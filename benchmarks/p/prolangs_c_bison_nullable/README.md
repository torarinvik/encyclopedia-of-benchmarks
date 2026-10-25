# Prolangs-C Bison nullable analysis

This package isolates Bison's `set_nullable` grammar-analysis kernel. It finds the least set of nonterminals that can derive the empty string. Empty productions seed the set; a production makes its left side nullable once every right-side symbol is itself a nullable nonterminal. A terminal in a production prevents that rule from contributing.

The pinned source scans the grammar, seeds nullable symbols from empty productions, then uses a queue and per-rule counts to propagate dependencies. These ports preserve that queue/count algorithm over a compact numeric grammar representation. They exclude Bison's grammar lexer, parser-table construction, conflict handling, file generation, and command-line driver.

## Contract

The scalar ABI is `int64_t prolangs_c_bison_nullable(const int64_t *input, size_t length)`. Input is:

```text
[nonterminal_count, terminal_count, rule_count,
 (lhs, rhs_length, rhs_symbol...)*]
```

There are 1–16 nonterminals, 0–16 terminals, and 1–32 rules. Each right-hand side contains zero to eight symbols. Nonterminal IDs are `0..nonterminal_count-1`; terminal IDs immediately follow, from `nonterminal_count` through `nonterminal_count+terminal_count-1`. The input length must match the production records exactly and is at most 323 integers.

The result is a bit mask: bit `i` is set exactly when nonterminal `i` is nullable. Invalid or null input returns `-1`. The source uses symbol IDs beginning at `ntokens` for variables; this contract shifts IDs to a zero-based nonterminal range while keeping the nullable analysis semantics.

## Provenance and rights

The workload is based on the `set_nullable` routine in [`Prolangs-C/bison/nullable.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/bison/nullable.c), with production storage semantics documented in `gram.h`. The pinned launcher compiles the Bison parser generator over `parse.y.in`; this package benchmarks the isolated nullable-analysis phase rather than the full application.

The pinned Bison subtree includes the Bison General Public License in `COPYING`. Each port retains the complete `nullable.c` attribution and warranty/license notice and identifies the 2026 bounded adaptation. The implementations are independently written; no upstream source code is copied. This package is distributed under the terms in [`COPYING`](COPYING).

## Workload and oracle

[`workload.json`](workload.json) includes a small source-shaped production set, dependency propagation, repeated RHS occurrences, a cycle without an empty seed, terminal blocking, malformed input, and a null input. The Python oracle uses repeated whole-grammar scans rather than the source's queue/dependency-count algorithm.

The oracle is [`benchmarks/prolangs_c_bison_nullable_oracle.py`](../../prolangs_c_bison_nullable_oracle.py).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/p/prolangs_c_bison_nullable.c`](../../../c/p/prolangs_c_bison_nullable.c) |
| C3 | [`c3/p/prolangs_c_bison_nullable.c3`](../../../c3/p/prolangs_c_bison_nullable.c3) |
| C++ | [`cpp/p/prolangs_c_bison_nullable.cpp`](../../../cpp/p/prolangs_c_bison_nullable.cpp) |
| Elisa | [`elisa/p/prolangs_c_bison_nullable.elisa`](../../../elisa/p/prolangs_c_bison_nullable.elisa) |
| Nim | [`nim/p/prolangs_c_bison_nullable.nim`](../../../nim/p/prolangs_c_bison_nullable.nim) |
| Odin | [`odin/p/prolangs_c_bison_nullable.odin`](../../../odin/p/prolangs_c_bison_nullable.odin) |
| Rust | [`rust/p/prolangs_c_bison_nullable.rs`](../../../rust/p/prolangs_c_bison_nullable.rs) |
| V | [`v/p/prolangs_c_bison_nullable.v`](../../../v/p/prolangs_c_bison_nullable.v) |
| Zig | [`zig/p/prolangs_c_bison_nullable.zig`](../../../zig/p/prolangs_c_bison_nullable.zig) |
