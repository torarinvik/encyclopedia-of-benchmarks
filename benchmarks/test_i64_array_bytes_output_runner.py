"""Exercise failure cleanup without depending on a real clock failure."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

class BytesRunnerCleanupTests(unittest.TestCase):
    def test_clock_failure_does_not_free_borrowed_expected_output(self):
        cc = shutil.which('cc')
        if cc is None:
            self.skipTest('C compiler unavailable')
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / 'fixture.c'
            fixture.write_text('#include <stdint.h>\n#include <stddef.h>\n#include <time.h>\n'
                'clock_t test_clock(void){return (clock_t)-1;}\n'
                'int64_t test(const int64_t*p,size_t n,uint8_t*out,size_t cap){return 0;}\n')
            binary = root / 'runner'
            source = Path(__file__).parent / 'harness/i64_array_bytes_output_runner.c'
            subprocess.run([cc, '-std=c11', '-O2', '-DBENCHMARK_FUNCTION=test',
                            '-Dclock=test_clock', str(source), str(fixture), '-o', str(binary)],
                           check=True, timeout=15)
            result = subprocess.run([str(binary), '0', '0', '-', '1', '0', '1'],
                                    capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 4, result.stderr)
            self.assertIn('clock() failed before a sample', result.stderr)

if __name__ == '__main__':
    unittest.main()
