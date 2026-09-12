import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('setup', ROOT / 'scripts/setup.py')
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='dotnix tests ')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.dest = self.root / 'custom config' / 'dotnix local'
        self.base = ['--no-install', '--non-interactive', '--destination', str(self.dest),
                     '--checkout', str(ROOT), '--platform', 'linux', '--arch', 'x86_64',
                     '--username', 'synthetic', '--home', '/srv/custom home', '--config-home', '/srv/xdg']

    def run_setup(self, *args):
        with contextlib.redirect_stdout(io.StringIO()):
            setup.main(self.base + list(args))

    def test_fresh_core(self):
        self.run_setup()
        machine = json.loads((self.dest / 'machine.json').read_text())
        prefs = json.loads((self.dest / 'preferences.json').read_text())
        self.assertEqual(machine['account']['homeDirectory'], '/srv/custom home')
        self.assertEqual(machine['mode'], 'home-manager')
        self.assertFalse(any(prefs['features'].values()))
        self.assertIn('git+file://', (self.dest / 'flake.nix').read_text())
        self.assertNotIn('--impure', (self.dest / 'flake.nix').read_text())

    def test_idempotent_and_reconfigure(self):
        self.run_setup('--enable', 'development')
        (self.dest / 'home.nix').write_text('{...}: { home.sessionVariables.TEST = "kept"; }')
        before = {p.name: p.read_bytes() for p in self.dest.iterdir()}
        self.run_setup('--enable', 'cloud')
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.dest.iterdir()})
        self.run_setup('--reconfigure', '--home', '/new home', '--disable', 'development')
        self.assertEqual(before['preferences.json'], (self.dest / 'preferences.json').read_bytes())
        self.assertEqual(before['home.nix'], (self.dest / 'home.nix').read_bytes())
        self.assertEqual(json.loads((self.dest / 'machine.json').read_text())['account']['homeDirectory'], '/new home')

    def test_rebind_preserves_flake_edits(self):
        self.run_setup()
        copy = self.root / 'moved checkout'
        copy.mkdir()
        for name in ('flake.nix', 'flake.lock'):
            (copy / name).write_text((ROOT / name).read_text())
        subprocess.run(['git', 'init', '-q', str(copy)], check=True)
        with (self.dest / 'flake.nix').open('a') as f:
            f.write('\n# local edits\n')
        self.run_setup('--reconfigure', '--checkout', str(copy))
        text = (self.dest / 'flake.nix').read_text()
        self.assertIn('moved%20checkout', text)
        self.assertIn('# local edits', text)

    def test_unsupported(self):
        with self.assertRaisesRegex(ValueError, 'Unsupported'):
            self.run_setup('--arch', 'aarch64')
        self.assertFalse(self.dest.exists())

    def test_conflict(self):
        self.dest.mkdir(parents=True)
        (self.dest / 'flake.nix').write_text('mine')
        with self.assertRaisesRegex(ValueError, 'unmanaged'):
            self.run_setup()
        self.assertEqual((self.dest / 'flake.nix').read_text(), 'mine')

    def test_wsl_detection(self):
        with patch.object(setup.platform, 'system', return_value='Linux'), patch.dict(os.environ, {}, clear=True):
            with patch.object(setup.platform, 'release', return_value='5.15-microsoft-standard-WSL2'):
                self.assertEqual(setup.detect_platform(), 'wsl')
            with patch.object(setup.platform, 'release', return_value='linux'), patch.dict(os.environ, {'WSL_INTEROP': '/run/wsl/test'}):
                self.assertEqual(setup.detect_platform(), 'wsl')

    def test_darwin_modes(self):
        self.run_setup('--platform', 'darwin', '--arch', 'arm64', '--mode', 'darwin', '--enable', 'desktop')
        prefs = json.loads((self.dest / 'preferences.json').read_text())
        self.assertTrue(prefs['features']['homebrew'])
        self.run_setup('--reconfigure', '--platform', 'darwin', '--arch', 'arm64')
        self.assertEqual(json.loads((self.dest / 'machine.json').read_text())['mode'], 'darwin')
        with self.assertRaisesRegex(ValueError, 'requires macOS'):
            self.run_setup('--reconfigure')

    def test_missing_optional_prerequisites(self):
        self.run_setup('--enable', 'homebrew', '--brew-executable', '/missing/custom brew')
        with self.assertRaisesRegex(ValueError, 'not executable'):
            setup.install_brew({'brewExecutable': '/missing/custom brew', 'platform': 'linux'})

    def test_existing_can_install_missing_brew_without_rewriting(self):
        self.run_setup('--enable', 'homebrew')
        before = (self.dest / 'preferences.json').read_bytes()
        with patch.object(setup, 'install_brew') as install, contextlib.redirect_stdout(io.StringIO()):
            setup.main([arg for arg in self.base if arg != '--no-install'])
        install.assert_called_once()
        self.assertEqual(before, (self.dest / 'preferences.json').read_bytes())

    def test_explicit_integration_settings(self):
        with self.assertRaisesRegex(ValueError, 'explicit'):
            self.run_setup('--enable', 'java')
        self.run_setup('--enable', 'java', '--jdk', 'jdk21')
        self.assertEqual(json.loads((self.dest / 'preferences.json').read_text())['settings']['jdk'], 'jdk21')


if __name__ == '__main__':
    unittest.main()
