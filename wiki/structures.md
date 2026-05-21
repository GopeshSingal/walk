# Structures

- If a `.str` file exists in a directory, that directory is then treated as a Struct.
- Any sibling `.fun` files in the same directory are automatically bound as its methods and injected with an implicit `self` keyword.
- If a method intends to modify the Struct's data, its static contract must declare `mut self` at the very top.
