# Phase 3: Semantic Geography and Context Injection

## Overview
Walk derives architecture from filesystem coordinates and file extensions. Phase 3 analyzes the keys of the AST map ("FilePath") and programmatically alters the AST nodes based on geographic proximity.

## Implementation

### Method Binding & Single-State Constraint
* **The Single-State Constraint:** A directory may only contain a single public ".str" file. Any supplemental data shapes in that directory must be private.
* **The Injection:** The compiler sweeps every "MethodAST". It verifies a public ".str" exists in the exact same directoy. If missing, it throws a fatal error. If found, it injects "in self: Namespace.State" or a mutable reference if "mut self" was parsed.

### Static Functions
* **The Rule:** Files with the ".fun" extension are completely decoupled from the local struct. They do not receive a "self" reference and act as static methods.

### Privacy Scoping
* ** The Rule:** Files or folders prefixed with an underscore ("_") are local-only. The compiler records an "AllowedCallerScope" constraint mapping to the immediate parent directory.
