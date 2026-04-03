import unittest
from unittest.mock import patch
from pathlib import Path
import io
import sys

from bundle import bundle_file, _normalize_path_prefix, _is_excluded

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

    def test_normalize_path_prefix(self):
        """Test _normalize_path_prefix with various edge cases."""
        cases = [
            ("A/B", "A/B"),
            ("A\\B", "A/B"),
            ("./A/B", "A/B"),
            ("././A/B", "A/B"),
            ("A/B/", "A/B"),
            ("/", "/"),
            ("", ""),
            (".", ""),
            ("./", ""),
        ]
        for input_path, expected in cases:
            with self.subTest(input_path=input_path):
                self.assertEqual(_normalize_path_prefix(input_path), expected)

    def test_is_excluded(self):
        """Test _is_excluded with various path scenarios."""
        # Exact matches
        self.assertTrue(_is_excluded("BOSL2", ["BOSL2"]))
        self.assertTrue(_is_excluded("BOSL2/std.scad", ["BOSL2"]))

        # Multiple prefixes
        self.assertTrue(_is_excluded("BOSL2/std.scad", ["other", "BOSL2"]))

        # Sub-path vs partial name
        self.assertTrue(_is_excluded("BOSL2/some/path", ["BOSL2"]))
        self.assertFalse(_is_excluded("BOSL2_old/some/path", ["BOSL2"]))

        # Path normalization in exclusion
        self.assertTrue(_is_excluded("./BOSL2/std.scad", ["BOSL2"]))
        self.assertTrue(_is_excluded("BOSL2\\std.scad", ["BOSL2"]))
        self.assertTrue(_is_excluded("BOSL2/std.scad", ["./BOSL2/"]))

        # Non-matching cases
        self.assertFalse(_is_excluded("MCAD/stepper.scad", ["BOSL2"]))
        self.assertFalse(_is_excluded("BOSL", ["BOSL2"]))

        # Empty prefix handling
        self.assertFalse(_is_excluded("BOSL2", [""]))
        self.assertFalse(_is_excluded("BOSL2", []))

if __name__ == "__main__":
    unittest.main()
