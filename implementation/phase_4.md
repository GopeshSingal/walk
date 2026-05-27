# Phase 4: Semantic Analysis & Type Checking

## Overview
Phase 4 connects the decoupled syntax trees into a cohesive, safe graph. This phase runs entirely in memory and leverages O(1) lookups for rapid validation.

## Implementation

### Explicit Composition & O(1) Type Checking
Walk enforces explicit composition. There is no implicit delegation. When the compiler evaluates `user.wallet.pay()`, it does zero graph searching. It explicitly checks the `models/wallet` directory for `pay.met` and validates the contract.

### Nominal Contract Fulfillment
* **Explicit Promises:** The compiler reads `req` declarations at the top of `.str` files.
* **Absolute Signature Equality:** To fulfill a `.req`, the struct's `.met` signatures must match the interface exactly. Covariance/contravariance on error bubbling (`!`) is strictly banned.

### Optimization Tagging
Functions operating strictly on primitives with no allocations are marked as Pure Primitive Functions.
