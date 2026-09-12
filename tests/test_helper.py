import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('helper', Path(__file__).resolve().parent.parent / 'scripts/dotnix.py')
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class HelperTests(unittest.TestCase):
    def invoke(self, mode='home-manager', build_fails=False):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        (root / '.dotnix-generated').touch()
        (root / 'machine.json').write_text(json.dumps({'checkout': str(root), 'mode': mode, 'account': {'username': 'example', 'homeDirectory': '/srv/example'}}))
        events = []

        def fake_nix(*args, **kwargs):
            events.append(args)
            if args[0] == 'eval':
                return json.dumps({'features': {'homebrew': False, 'onePassword': False, 'athens': False, 'browser': False}})
            if args[0] == 'build':
                if build_fails:
                    raise ValueError('build failed')
                return '/nix/store/runner' if args[-1].endswith('#darwin-activate') else '/nix/store/system'

        def command(args, **kwargs):
            events.append(tuple(args))
            return type('Result', (), {'stdout': ''})()

        with patch('sys.argv', ['dotnix', '--config', str(root), 'rebuild']), patch.object(helper, 'nix', side_effect=fake_nix), patch.object(helper, 'verify_locks'), patch.object(helper.shutil, 'which', return_value='/bin/nix'), patch.object(helper.subprocess, 'run', side_effect=command), contextlib.redirect_stdout(io.StringIO()):
            if build_fails:
                with self.assertRaises(ValueError):
                    helper.main()
            else:
                helper.main()
        return events

    def test_home_build_before_activation(self):
        events = self.invoke()
        self.assertEqual(next(e for e in events if e[0] == 'flake')[:3], ('flake', 'update', 'dotnix'))
        self.assertEqual(events[-1], ('/nix/store/system/activate',))
        self.assertEqual(events[-2][0], 'build')
        self.assertFalse(any(e[0] == 'sudo' for e in events))

    def test_darwin_elevates_only_built_activation(self):
        events = self.invoke('darwin')
        self.assertEqual(events[-1], ('sudo', '/nix/store/runner/bin/dotnix-darwin-activate', '/nix/store/system'))
        self.assertEqual(sum(e[0] == 'sudo' for e in events), 1)

    def test_build_failure_never_activates(self):
        events = self.invoke(build_fails=True)
        self.assertFalse(any(e[0] == 'sudo' or e[0].endswith('/activate') for e in events))

    def test_lock_mismatch_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'source'; source.mkdir()
            local = root / 'local'; local.mkdir()
            (source / 'flake.lock').write_text(json.dumps({'root': 'root', 'nodes': {'root': {'inputs': {'nixpkgs': 'nixpkgs'}}, 'nixpkgs': {'locked': {'rev': 'wanted'}}}}))
            (local / 'flake.lock').write_text(json.dumps({'root': 'root', 'nodes': {'root': {'inputs': {'dotnix': 'dotnix'}}, 'dotnix': {'inputs': {'nixpkgs': 'nixpkgs'}}, 'nixpkgs': {'locked': {'rev': 'changed'}}}}))
            with self.assertRaisesRegex(ValueError, 'differs'):
                helper.verify_locks(source, local)


if __name__ == '__main__':
    unittest.main()
