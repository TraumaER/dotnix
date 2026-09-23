#!/usr/bin/env python3
"""Generate a local flake. Machine facts never enter shared Nix evaluation."""
import argparse
import json
import os
from pathlib import Path
import platform
import pwd
import shutil
import subprocess
import sys
from urllib.parse import quote

FEATURES = ('development containers colima cloud desktop homebrew nvm keychain signing '
            'githubSsh onePassword java browser athens').split()


def detect_platform():
    kernel = platform.system().lower()
    if kernel == 'darwin':
        return 'darwin'
    if kernel == 'linux':
        markers = platform.release() + platform.version()
        if os.environ.get('WSL_DISTRO_NAME') or os.environ.get('WSL_INTEROP') or 'microsoft' in markers.lower():
            return 'wsl'
        return 'linux'
    return kernel


def write_json(path, data):
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(data, indent=2) + '\n')
    temporary.replace(path)


def flake_text(checkout):
    url = 'git+file://' + quote(str(checkout), safe='/')
    return '''{
  description = "Local dotnix configuration";
  inputs.dotnix.url = %s;
  outputs = {self, dotnix}: let
    machine = builtins.fromJSON (builtins.readFile ./machine.json);
    preferences = builtins.fromJSON (builtins.readFile ./preferences.json);
    args = {
      inherit (machine) account system platform localDirectory;
      inherit (preferences) features settings;
    };
  in {
    homeConfigurations.default = dotnix.lib.mkHomeConfiguration (args // {modules = [./home.nix];});
    packages.${machine.system} = dotnix.packages.${machine.system};
  } // (if machine.mode == "darwin" then {
    darwinConfigurations.default = dotnix.lib.mkDarwinConfiguration (args // {
      modules = [./darwin.nix];
      homeModulesExtra = [./home.nix];
    });
  } else {});
}
''' % json.dumps(url)


def install_brew(machine):
    executable = Path(machine['brewExecutable'])
    if executable.is_file() and os.access(executable, os.X_OK):
        return
    conventional = '/opt/homebrew/bin/brew' if machine['platform'] == 'darwin' else '/home/linuxbrew/.linuxbrew/bin/brew'
    if str(executable) != conventional:
        raise ValueError('Custom Brew executable is missing or not executable: ' + str(executable))
    if machine['platform'] == 'darwin':
        if subprocess.run(['xcode-select', '-p'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
            subprocess.run(['xcode-select', '--install'], check=True)
            raise ValueError('Complete Command Line Tools installation, then rerun setup.')
    else:
        if shutil.which('apt-get'):
            subprocess.run(['sudo', 'apt-get', 'update'], check=True)
            command = ['apt-get', 'install', '-y', 'build-essential', 'procps', 'curl', 'file', 'git']
        elif shutil.which('dnf'):
            command = ['dnf', 'install', '-y', 'gcc', 'gcc-c++', 'make', 'procps-ng', 'curl', 'file', 'git']
        else:
            raise ValueError('Install Homebrew prerequisites and Homebrew manually on this Linux distribution.')
        subprocess.run(['sudo'] + command, check=True)
    import tempfile
    with tempfile.TemporaryDirectory() as directory:
        installer = Path(directory) / 'brew-install.sh'
        subprocess.run(['curl', '-fsSL', 'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh', '-o', str(installer)], check=True)
        subprocess.run(['/bin/bash', str(installer)], check=True)
    if not executable.is_file() or not os.access(executable, os.X_OK):
        raise ValueError('Homebrew installation did not provide ' + str(executable))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path)
    parser.add_argument('--checkout', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--username')
    parser.add_argument('--home', type=Path)
    parser.add_argument('--config-home', type=Path)
    parser.add_argument('--platform', choices=['darwin', 'linux', 'wsl'])
    parser.add_argument('--arch')
    parser.add_argument('--mode', choices=['home-manager', 'darwin'])
    parser.add_argument('--enable', action='append', default=[], choices=FEATURES)
    parser.add_argument('--disable', action='append', default=[], choices=FEATURES)
    parser.add_argument('--brew-executable')
    parser.add_argument('--signing-key')
    parser.add_argument('--signing-format', choices=['ssh', 'openpgp'], default='ssh')
    parser.add_argument('--one-password-socket')
    parser.add_argument('--jdk')
    parser.add_argument('--browser')
    parser.add_argument('--athens-image')
    parser.add_argument('--reconfigure', action='store_true', help='Refresh machine.json and source binding; retain preferences and local modules')
    parser.add_argument('--non-interactive', action='store_true')
    parser.add_argument('--no-install', action='store_true', help='Generate only; do not install prerequisites')
    args = parser.parse_args(argv)
    target = args.platform or detect_platform()
    arch = args.arch or platform.machine()
    arch = {'arm64': 'aarch64', 'amd64': 'x86_64'}.get(arch, arch)
    if (target, arch) not in [('darwin', 'aarch64'), ('linux', 'x86_64'), ('wsl', 'x86_64')]:
        raise ValueError(f'Unsupported target: {target}/{arch}')
    account = pwd.getpwuid(os.getuid())
    if args.username and not args.home:
        account = pwd.getpwnam(args.username)
    home = args.home or Path(account.pw_dir)
    config_home = args.config_home or Path(os.environ.get('XDG_CONFIG_HOME', str(home / '.config')))
    for path in (home, config_home):
        if not path.is_absolute():
            raise ValueError('Home and XDG configuration paths must be absolute')
    destination = (args.destination or config_home / 'dotnix-local').absolute()
    checkout = args.checkout.resolve()
    if not (checkout / 'flake.lock').is_file() or not (checkout / 'flake.nix').is_file():
        raise ValueError('Checkout must contain flake.nix and flake.lock')
    subprocess.run(['git', '-C', str(checkout), 'rev-parse', '--show-toplevel'], check=True, stdout=subprocess.DEVNULL)
    marker = destination / '.dotnix-generated'
    existing = marker.is_file()
    if destination.exists() and any(destination.iterdir()) and not existing:
        raise ValueError('Destination contains unmanaged files; choose another --destination')
    if existing and not args.reconfigure:
        saved_machine = json.loads((destination / 'machine.json').read_text())
        saved_preferences = json.loads((destination / 'preferences.json').read_text())
        if not args.no_install and saved_preferences['features'].get('homebrew'):
            saved_machine['brewExecutable'] = saved_preferences.get('settings', {}).get('brew', {}).get('executable', saved_machine['brewExecutable'])
            install_brew(saved_machine)
        print(f'Preserved existing configuration at {destination}. Use --reconfigure to refresh machine information.')
        return
    previous = json.loads((destination / 'machine.json').read_text()) if existing else {}
    mode = args.mode or previous.get('mode') or ('darwin' if target == 'darwin' and Path('/nix/var/nix/profiles/system').exists() else 'home-manager')
    preferences = {'features': {f: f in args.enable and f not in args.disable for f in FEATURES}, 'settings': {}}
    if not existing and not args.non_interactive and sys.stdin.isatty():
        if target == 'darwin' and not args.mode:
            if input(f'Deployment mode [{mode}] (home-manager/darwin): ').strip() == 'darwin':
                mode = 'darwin'
        for feature in FEATURES:
            if feature not in args.enable + args.disable:
                preferences['features'][feature] = input(f'Enable {feature}? [y/N] ').strip().lower() in ('y', 'yes')
    if not existing and target == 'darwin' and preferences['features'].get('desktop'):
        if 'homebrew' in args.disable:
            raise ValueError('macOS desktop applications require Homebrew')
        preferences['features']['homebrew'] = True
    if mode == 'darwin' and target != 'darwin':
        raise ValueError('Darwin integration requires macOS. Use --mode home-manager when moving to Linux.')
    settings = preferences['settings']
    for arg, name in [(args.jdk, 'jdk'), (args.browser, 'browser'), (args.athens_image, 'athensImage'), (args.one_password_socket, 'onePasswordSocket')]:
        if arg:
            settings[name] = arg
    if args.signing_key:
        settings['signing'] = {'key': args.signing_key, 'format': args.signing_format}
    if existing:
        preferences = json.loads((destination / 'preferences.json').read_text())
        settings = preferences['settings']
    for feature, name in [('java', 'jdk'), ('browser', 'browser'), ('athens', 'athensImage'), ('onePassword', 'onePasswordSocket'), ('signing', 'signing')]:
        if preferences['features'].get(feature) and not settings.get(name):
            if not existing and not args.non_interactive and sys.stdin.isatty():
                value = input(f'Explicit value for {name}: ').strip()
                settings[name] = {'key': value, 'format': args.signing_format} if feature == 'signing' else value
            if not settings.get(name):
                raise ValueError(f'{feature} requires an explicit {name} setting')
    if preferences['features'].get('onePassword') and preferences['features'].get('keychain'):
        raise ValueError('Select only one SSH agent integration')
    brew = args.brew_executable or ('/opt/homebrew/bin/brew' if target == 'darwin' else '/home/linuxbrew/.linuxbrew/bin/brew')
    if not Path(brew).is_absolute():
        raise ValueError('Brew executable must be an absolute path')
    machine = {'account': {'username': args.username or account.pw_name, 'homeDirectory': str(home), 'configHome': str(config_home)},
               'system': arch + ('-darwin' if target == 'darwin' else '-linux'), 'platform': target,
               'mode': mode, 'checkout': str(checkout), 'localDirectory': str(destination), 'brewExecutable': brew}
    if not args.no_install and preferences['features'].get('homebrew'):
        brew_machine = dict(machine)
        brew_machine['brewExecutable'] = settings.get('brew', {}).get('executable', brew)
        install_brew(brew_machine)
    # Rebinding changes only the generated URL, preserving other flake edits.
    flake = flake_text(checkout)
    if existing:
        old_url = json.dumps('git+file://' + quote(previous['checkout'], safe='/'))
        new_url = json.dumps('git+file://' + quote(str(checkout), safe='/'))
        flake = (destination / 'flake.nix').read_text()
        if old_url not in flake:
            raise ValueError('Source binding was edited; update inputs.dotnix.url manually before reconfiguring')
        flake = flake.replace(old_url, new_url, 1)
    destination.mkdir(parents=True, exist_ok=True)
    destination.chmod(0o700)
    if not existing:
        write_json(destination / 'preferences.json', preferences)
        (destination / 'home.nix').write_text('''{...}: {
  # Add Git identity, work environment, signers and packages here.
  # programs.git.settings.user = { name = "Your Name"; email = "you@example.org"; };
}
''')
        (destination / 'darwin.nix').write_text('{...}: {\n  # Local nix-darwin customization.\n}\n')
    write_json(destination / 'machine.json', machine)
    # Brew's location is machine information; preferences can override it explicitly.
    flake = flake.replace('inherit (preferences) features settings;', 'inherit (preferences) features;\n      settings = preferences.settings // {brew = {executable = machine.brewExecutable;} // (preferences.settings.brew or {});};')
    (destination / 'flake.nix').write_text(flake)
    marker.write_text('1\n')
    import shlex
    print(f'Configuration generated at {destination}; nothing activated.')
    print(f'Run: {shlex.quote(str(checkout / "scripts/dotnix"))} --config {shlex.quote(str(destination))} doctor')
    print('Then use the same command with build or rebuild.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
