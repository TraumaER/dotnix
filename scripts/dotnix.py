#!/usr/bin/env python3
"""Build and activate the generated local configuration without upstream updates."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from urllib.parse import quote


def nix(*args, capture=False):
    command = ['nix', '--extra-experimental-features', 'nix-command flakes', '--option', 'allow-dirty-locks', 'true', *args]
    return subprocess.run(command, check=True, text=True, stdout=subprocess.PIPE if capture else None).stdout


def verify_locks(source, local):
    expected = json.loads((source / 'flake.lock').read_text())
    actual = json.loads((local / 'flake.lock').read_text())
    # Resolve the dependency graph instead of assuming Nix's generated node names.
    nodes = actual['nodes']
    root = nodes[actual['root']]
    dotnix_name = root['inputs']['dotnix']
    dotnix = nodes[dotnix_name]
    for name, source_node in expected['nodes'][expected['root']]['inputs'].items():
        node = dotnix['inputs'][name]
        if not isinstance(node, str) or nodes[node].get('locked') != expected['nodes'][source_node].get('locked'):
            raise ValueError(f'Local dependency {name} differs from checkout lock. Remove only the local flake.lock and retry.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, default=Path(os.environ.get('DOTNIX_LOCAL', str(Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'dotnix-local'))))
    parser.add_argument('command', choices=['build', 'rebuild', 'doctor'])
    args = parser.parse_args()
    local = args.config.resolve()
    if not (local / '.dotnix-generated').is_file():
        raise ValueError(f'No generated configuration at {local}; run setup.sh first.')
    machine = json.loads((local / 'machine.json').read_text())
    source = Path(machine['checkout'])
    if not source.is_dir():
        raise ValueError('Checkout moved; rerun setup.sh --reconfigure --destination with its new path.')
    if not shutil.which('nix'):
        raise ValueError('Nix is missing; run setup.sh.')
    untracked = subprocess.run(['git', '-C', str(source), 'ls-files', '--others', '--exclude-standard'], check=True, text=True, stdout=subprocess.PIPE).stdout.strip()
    if untracked:
        print('Untracked checkout files are excluded by git+file inputs. Add intended source files with git add:\n' + untracked, file=sys.stderr)
    # path: also handles local configurations kept beneath an ignored checkout directory.
    ref = 'path:' + quote(str(local), safe='/')
    nix('flake', 'update', 'dotnix', '--flake', ref)
    verify_locks(source, local)
    integrated = machine['mode'] == 'darwin'
    attr = 'darwinConfigurations.default.config' if integrated else 'homeConfigurations.default.config'
    # Read effective module settings so local overrides participate in doctor.
    cfg = json.loads(nix('eval', '--json', ref + '#' + attr + ('.home-manager.users.' + machine['account']['username'] if integrated else '') + '.dotnix', capture=True))
    problems = []
    if cfg['features']['homebrew'] and not os.access(cfg['brew']['executable'], os.X_OK):
        problems.append('Homebrew is missing/not executable: ' + cfg['brew']['executable'])
    if cfg['features']['onePassword'] and (not cfg['onePasswordSocket'] or not Path(cfg['onePasswordSocket']).exists()):
        problems.append('1Password agent socket missing; enable its SSH agent.')
    if cfg['features']['athens']:
        if not shutil.which('docker'):
            problems.append('Athens requires Docker CLI/Compose and a running Docker daemon.')
        if not (Path(machine['account']['homeDirectory']) / '.local/athens/.netrc').is_file():
            problems.append('Athens requires ~/.local/athens/.netrc credentials before starting the proxy.')
    if cfg['features']['browser'] and (not cfg['browser'] or not os.access(cfg['browser'], os.X_OK)):
        problems.append('Configured browser is missing/not executable: ' + str(cfg['browser']))
    if problems:
        raise ValueError('\n'.join(problems))
    if args.command == 'doctor':
        home_attr = attr + ('.home-manager.users.' + machine['account']['username'] if integrated else '')
        files = json.loads(nix('eval', '--json', ref + '#' + home_attr + '.home.file', '--apply',
                              'files: builtins.mapAttrs (_: f: { inherit (f) target force; }) files', capture=True))
        for entry in files.values():
            target = Path(machine['account']['homeDirectory']) / entry['target']
            if os.path.lexists(target) and not entry['force']:
                managed = target.is_symlink() and '-home-manager-files/' in os.readlink(target)
                if not managed:
                    print('Potential unmanaged-file collision (review before activation): ' + str(target), file=sys.stderr)
        nix('eval', '--raw', ref + ('#darwinConfigurations.default.system.drvPath' if integrated else '#homeConfigurations.default.activationPackage.drvPath'))
        print('\nConfiguration evaluates. Home Manager checks file collisions during activation; back up conflicts explicitly.')
        return
    target = '#darwinConfigurations.default.system' if integrated else '#homeConfigurations.default.activationPackage'
    output = nix('build', '--no-link', '--print-out-paths', ref + target, capture=True).strip()
    print('Built ' + output)
    if args.command == 'rebuild':
        if integrated:
            runner = nix('build', '--no-link', '--print-out-paths', ref + '#darwin-activate', capture=True).strip()
            subprocess.run(['sudo', str(Path(runner) / 'bin/dotnix-darwin-activate'), output], check=True)
        else:
            subprocess.run([str(Path(output) / 'activate')], check=True)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
