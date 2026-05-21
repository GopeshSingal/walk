# Safety

Walk is designed to catch bugs at compile-time, not execution-time through the following means:

- Strict Optionals (`?`): Variables cannot be secretly null. If a value might be missing, it must be explicitly typed with `?` (e.g., `middle_name: String?`).
- Errors as Values (`!`): Walk has no `try/catch` blocks. Functions that can fail declare `!` in their output. Callers handle errors by bubbling them up (appending `!`) or by providing a fallback using the `else` keyword.
- Immutability: Variables are locked upon creation (`let x = 10`). Reassignment requires explicit permission through the keyword `mut` (`let mut x = 10`).
