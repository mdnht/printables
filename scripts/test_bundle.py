import unittest
from pathlib import Path
import tempfile

from bundle import resolve_path, _normalize_path_prefix, _is_excluded

class TestBundle(unittest.TestCase):
    def test_normalize_path_prefix(self):
        self.assertEqual(_normalize_path_prefix("a\\b"), "a/b")
        self.assertEqual(_normalize_path_prefix("./a/b"), "a/b")
        self.assertEqual(_normalize_path_prefix("a/b/"), "a/b")
        self.assertEqual(_normalize_path_prefix("/"), "/")
        self.assertEqual(_normalize_path_prefix(""), "")
        self.assertEqual(_normalize_path_prefix("./"), "")

    def test_is_excluded(self):
        self.assertTrue(_is_excluded("BOSL2/std.scad", ["BOSL2"]))
        self.assertTrue(_is_excluded("BOSL2", ["BOSL2"]))
        self.assertFalse(_is_excluded("BOSL2_other/file.scad", ["BOSL2"]))
        self.assertTrue(_is_excluded("libs/common.scad", ["libs/"]))
        self.assertTrue(_is_excluded("libs/common.scad", ["libs"]))
        self.assertFalse(_is_excluded("mylibs/common.scad", ["libs"]))
        # Normalization in _is_excluded
        self.assertTrue(_is_excluded("BOSL2\\std.scad", ["BOSL2"]))

    def test_resolve_path(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir).resolve()

            # Create some files
            dir1 = tmp_path / "dir1"
            dir1.mkdir()
            file1 = dir1 / "file1.scad"
            file1.touch()

            dir2 = tmp_path / "dir2"
            dir2.mkdir()
            file2 = dir2 / "file2.scad"
            file2.touch()

            # File that exists in both
            common_file1 = dir1 / "common.scad"
            common_file1.write_text("dir1")
            common_file2 = dir2 / "common.scad"
            common_file2.write_text("dir2")

            # Test resolving relative to current_dir
            self.assertEqual(resolve_path("file1.scad", dir1, []), file1)

            # Test resolving from search_dirs
            self.assertEqual(resolve_path("file2.scad", dir1, [dir2]), file2)

            # Test priority: current_dir first
            resolved = resolve_path("common.scad", dir1, [dir2])
            self.assertEqual(resolved, common_file1)
            self.assertEqual(resolved.read_text(), "dir1")

            # Test search_dirs order
            resolved = resolve_path("common.scad", tmp_path, [dir2, dir1])
            self.assertEqual(resolved, common_file2)
            self.assertEqual(resolved.read_text(), "dir2")

            # Test not found
            self.assertIsNone(resolve_path("nonexistent.scad", dir1, [dir2]))

if __name__ == "__main__":
    unittest.main()
