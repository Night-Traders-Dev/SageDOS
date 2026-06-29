# filesystem.sage — DOS-like filesystem operations
# Phase 6: Wraps Sage's io module with DOS-path semantics.
# Handles backslash normalization, glob expansion, and
# directory operations used by internal commands.

import sys

class FileSystem:
    proc init(self, env):
        self.env = env

    proc normalize(self, path):
        return replace(path, "\\", "/")

    proc abs_path(self, path):
        let p = self.normalize(path)
        let dos_path = ""
        if startswith(p, "/"):
            dos_path = p
        else:
            if self.env.cwd == "/":
                dos_path = "/" + p
            else:
                dos_path = self.env.cwd + "/" + p
        # Basic normalize for ..
        if endswith(dos_path, "/.."):
            let parts = split(dos_path, "/")
            if len(parts) > 2:
                dos_path = "/" + join(slice(parts, 1, len(parts) - 2), "/")
            else:
                dos_path = "/"
        if dos_path == "":
            dos_path = "/"
        return dos_path

    proc resolve(self, path):
        let dos_path = self.abs_path(path)
                
        # map DOS path to Linux path
        if dos_path == "/":
            return "."
        if startswith(dos_path, "/"):
            return "." + dos_path
        return dos_path

    proc exists(self, path):
        return io_exists(self.resolve(path))

    proc is_dir(self, path):
        return io_isdir(self.resolve(path))

    proc is_file(self, path):
        return self.exists(path)

    proc read_file(self, path):
        return io_readfile(self.resolve(path))

    proc write_file(self, path, content):
        io_writefile(self.resolve(path), content)

    proc append_file(self, path, content):
        let res = self.resolve(path)
        let existing = io_readfile(res)
        if existing == nil:
            existing = ""
        io_writefile(res, existing + content)

    proc delete_file(self, path):
        io_remove(self.resolve(path))

    proc make_dir(self, path):
        let res = io_mkdir(self.resolve(path))
        if not res:
            raise "MD: Could not create directory " + path

    proc remove_dir(self, path):
        let res = io_remove(self.resolve(path))
        if not res:
            raise "RD: Could not remove directory " + path

    proc list_dir(self, path):
        let res = self.resolve(path)
        return io_listdir(res)

    proc glob(self, pattern):
        return [pattern]

    proc copy_file(self, src, dst):
        let content = self.read_file(src)
        self.write_file(dst, content)

    proc move_file(self, src, dst):
        self.copy_file(src, dst)
        self.delete_file(src)

    proc rename_file(self, src, dst):
        self.move_file(src, dst)
