"""Exercise the paired runner's validation and result protocol."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class PairedRunnerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.root = Path(cls.directory.name)
        cc = shutil.which('cc')
        if cc is None:
            raise unittest.SkipTest('C compiler unavailable')
        cls.runner = cls.root / 'pair'
        source = Path(__file__).parent / 'harness/i64_array_scalar_pair.c'
        flags = [] if sys.platform == 'darwin' else ['-ldl']
        subprocess.run([cc, '-std=c11', '-O2', str(source), '-o', str(cls.runner), *flags], check=True, timeout=15)
        fixture = cls.root / 'fixture.c'
        fixture.write_text('#include <stdint.h>\n#include <stddef.h>\n'
            'int64_t good(const int64_t*p,size_t n){return n?p[0]:0;}\n'
            'int64_t wrong(const int64_t*p,size_t n){return 0;}\n'
            'int64_t mutate(const int64_t*p,size_t n){int64_t v=p[0];((int64_t*)p)[0]++;return v;}\n')
        cls.library = cls.root / 'fixture.so'
        shared = '-dynamiclib' if sys.platform == 'darwin' else '-shared'
        subprocess.run([cc, shared, '-fPIC', str(fixture), '-o', str(cls.library)], check=True, timeout=15)

    @classmethod
    def tearDownClass(cls):
        cls.directory.cleanup()

    def run_pair(self, **changes):
        args = [str(self.library), str(self.library), 'good', '3', '4', '10', '7', '7']
        positions = {'library': 0, 'symbol': 2, 'rounds': 3, 'batches': 4, 'repetitions': 5, 'expected': 6, 'input': 7}
        for key, value in changes.items():
            args[positions[key]] = value
        return subprocess.run([str(self.runner), *args], capture_output=True, text=True, timeout=5)

    def test_protocol(self):
        result = self.run_pair()
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = [json.loads(line) for line in result.stdout.splitlines()]
        self.assertEqual([row['round'] for row in rows], [0, 1, 2])
        self.assertTrue(all(row['a_ns'] >= 0 and row['b_ns'] >= 0 for row in rows))

    def test_rejects_invalid_arguments(self):
        for change in ({'rounds': '0'}, {'rounds': '-1'}, {'batches': 'x'},
                       {'repetitions': '1000000001'}, {'input': '9223372036854775808'},
                       {'input': '7garbage'}):
            with self.subTest(change=change):
                self.assertEqual(self.run_pair(**change).returncode, 2)

    def test_rejects_missing_library_and_symbol(self):
        self.assertEqual(self.run_pair(library='/does/not/exist').returncode, 2)
        self.assertEqual(self.run_pair(symbol='missing').returncode, 2)

    def test_rejects_wrong_results_and_mutation(self):
        self.assertEqual(self.run_pair(symbol='wrong').returncode, 1)
        self.assertEqual(self.run_pair(symbol='mutate').returncode, 1)
        self.assertEqual(self.run_pair(expected='8').returncode, 1)


if __name__ == '__main__':
    unittest.main()
