# Phase 5: The Amalgamation Generation

## Overview
C requires all data types and functions to be declared before they are called. The transpiler pre-declares the entire codebase structure at the top of the final compilation block to bypass legacy C ordering rules.

## Implementation

### Monolithic Forward Declarations
* Loop over all validated ".fun" and ".met" AST nodes. Translate their parameter signatures into standard C function headers.
* Concatenate these directly underneath the sorted struct definitions to form the "walk_generated_headers.h" string.
