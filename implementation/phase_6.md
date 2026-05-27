# Phase 6: Unity Build & Arena Optimization

## Overview
This phase emits the logic bodies into high-performance C, managing memory via zero-latency, region-based arenas and generating static VTables.

## Implementation

### The Scratch / Permanent Arena Pattern
* Transpiled functions accept two implicitly arguments: `Arena* perm_arena` and `Arena* scatch_arena`.
* Temporary allocations slice from `scratch_arena`. Return data is written directly to `perm_arena` (no deep copies).
* The caller resets the offset of `scratch_arena` instantly upon return.
* **Pure Primitive Optimization:** Functions tagged as pure drop the arena parameters and use standard C stack returns.

### Static VTable Generation
Because `.str` files explicitly declare their `.req` fulfilments, the transpiler generates exactly **one** static C VTable struct per fulfilled interface globally. No dynamic fat-pointer construction is required at runtime.

### Emitting the Unity Build
The generation stage concatenates the unified header block followed by the emitted logic loops into a singular source file: `walk_output.c`.
