# Phase 2: Parallel Parsing

## Overview
Traditional parsers can be bottlenecked by inline scope crawling and jumping around the file system via imports. Walk does this as a flat operations map, evaluating individual file contents as isolated Micro-ASTs.

## Implementation

### Target Data Structure
The output transforms the raw text dictionary into a typed syntax tree dictionary:
`Data.Map.Strict FilePath WalkAST`

### Execution Flow
* **Grammar Execution:** Leverage the `megaparsec` library to parse Walk's clean token constraints.
* **Context-Free Parsing:** The parser does not look up identifiers or evaluate if modules exists yet.
* **Strict Mutability Syntax:** When parsing a `.met` file, the parser strictly enforces that if the method requires struct modification, the exact string `mut self` must be the very first line of the file.
* **Parallel Core Saturation:** Use Haskell's `Control.Concurrent.Async` module via `mapConcurrently` to parse the entire map across all hardware CPU threads concurrently.
