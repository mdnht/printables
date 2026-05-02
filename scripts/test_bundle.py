import unittest
from unittest.mock import patch
from pathlib import Path
import io
import sys

from bundle import bundle_file, _normalize_path_prefix, _is_excluded, _sanitize_source

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

    def test_sanitize_source(self):
        """Test _sanitize_source with various scenarios."""
        cases = [
            ("Empty string", "", ""),
            ("No comments or strings", "cube(10);", "cube(10);"),
            ("Single-line comment", "cube(10); // comment", "cube(10);           "),
            ("Single-line comment with newline", "code(); // comment\nmore();", "code();           \nmore();"),
            ("Multi-line comment", "/* comment */ cube(10);", "              cube(10);"),
            ("Multi-line comment with newlines", "/*\n comment\n */ cube(10);", "  \n        \n    cube(10);"),
            ("String literal", 's = "hello";', 's =        ;'),
            ("Escaped quote in string", 's = "he\\"llo";', 's =          ;'),
            ("Comment symbols in string", 's = "// /* */";', 's =           ;'),
            ("Quotes in single-line comment", '// "quote"', '          '),
            ("Quotes in multi-line comment", '/* "quote" */', '             '),
            ("Unclosed string", '"unclosed', '         '),
            ("Unclosed multi-line comment", '/* unclosed', '           '),
        ]

        for name, input_str, expected in cases:
            with self.subTest(name=name):
                result = _sanitize_source(input_str)
                self.assertEqual(result, expected, f"Failed case: {name}")
                self.assertEqual(len(result), len(input_str), f"Length mismatch in case: {name}")

    def test_sanitize_source_complex(self):
        """Test _sanitize_source with a complex OpenSCAD-like snippet."""
        source = (
            "module x() {\n"
            "  // comment here\n"
            "  s = \"str /* not a comment */\";\n"
            "  /* multi-line\n"
            "     comment */\n"
            "  cube(10);\n"
            "}"
        )
        # Expected:
        # "module x() {\n"
        # "                 \n"
        # "  s =                          ;\n"
        # "               \n"
        # "               \n"
        # "  cube(10);\n"
        # "}"

        # Let's be precise about spaces.
        # "// comment here" -> 15 characters (including //) replaced by 15 spaces.
        # "\"str /* not a comment */\"" -> " + 23 chars + " = 25 chars replaced by 25 spaces.

        result = _sanitize_source(source)

        # Verify lines count
        self.assertEqual(result.count('\n'), source.count('\n'))

        # Verify that non-comment/string parts are preserved
        self.assertIn("module x() {", result)
        self.assertIn("s = ", result)
        self.assertIn("cube(10);", result)
        self.assertIn("}", result)

        # Verify that comments and strings are gone
        self.assertNotIn("comment here", result)
        self.assertNotIn("str /* not a comment */", result)
        self.assertNotIn("multi-line", result)

        # Verify length
        self.assertEqual(len(result), len(source))

if __name__ == "__main__":
    unittest.main()
