# Structures

- If a `.str` file exists in a directory, that directory is considered as a Struct.
- There can only be one `.str` file per directory.
- Any `.met` files in the directory are considered structure methods. If a `.met` file needs to modify its struct, `mut self` must be explicity written on the very first line of the file.
