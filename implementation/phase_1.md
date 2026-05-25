# Phase 1: The Upfront Snapshot

## Overview
Walk completely eliminates the "import" statement; the compiler cannot rely on text-driven parsing to discover dependencies. Therefore, Phase 1 of compilation involves an absolute, upfront sweep of the entire project directory to build an exhaustive map of the project universe. 

## Implementation

### Target Data Structure
The primary output of this phase is the **Global Symbol Dictionary**, represented in Haskell as a strict Map:
"Data.Map.Strict FilePath Text"

### Execution Flow
* **Enter the "IO" Monad:** The compiler begins in "IO" to interact with the host OS file system.
* **"I/O Black Hole" Prevention:** The compiler filters out paths against a hardcoded ignore list.
* **Recursive Sweep:** Collect all file paths with Walk extensions.
* **Namespace Collision Validation:** The scanner enforces that entity base names must be unique within a directory, even with different extensions.
* **Capture & Freeze:** Read the text content of all unique valid files into memory.
* **Exit "IO":** Once the dictionary has been built, the compiler drops all "IO" privileges.
