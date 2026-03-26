import unittest
from unittest.mock import patch, MagicMock
from pathlib import Path
import io
import sys

from bundle import bundle_file

class TestBundle(unittest.TestCase):
    def test_bundle_file_oserror(self):
        """Test that bundle_file handles OSError when reading a file."""
        dummy_path = Path("/dummy/path/main.scad")

        with patch.object(Path, 'read_text', side_effect=OSError("Read error")):
            with patch('sys.stderr', new=io.StringIO()) as fake_stderr:
                result = bundle_file(dummy_path, [], set())

                # Check return value
                self.assertEqual(result, f"// WARNING: could not read {dummy_path}\n")

                # Check stderr output
                stderr_val = fake_stderr.getvalue()
                self.assertIn(f"WARNING: cannot read {dummy_path}: Read error", stderr_val)

    def test_bundle_file_success(self):
        """Test that bundle_file successfully reads file content."""
        dummy_path = Path("/dummy/path/main.scad")
        content = "cube(10);"

        with patch.object(Path, 'read_text', return_value=content):
            result = bundle_file(dummy_path, [], set())
            self.assertEqual(result, content)

if __name__ == "__main__":
    unittest.main()
