# Aho–Corasick failure-tree occurrence counts

This package benchmarks per-pattern overlapping occurrence counts using offline failure-tree aggregation. It constructs a trie automaton, increments one counter for each state reached while scanning the text, and propagates those visits to failure-link parents in reverse breadth-first order. Each terminal trie state then contains the count for its pattern.

The existing [`aho_corasick`](../aho_corasick/README.md) profile follows terminal failure links during the text scan. This profile removes work proportional to the number of reported matches: its scan records one state visit per text symbol, then performs one aggregation pass over the trie states. The output contract remains one count per input pattern.

## Contract

The `i64_array_bytes_output` input is `[P,T,lengths[P],pattern_symbols...,text_symbols...]`. There are 1–16 unique patterns, each 1–32 symbols long, and 0–256 text symbols. Pattern and text symbols are integers 1–4. The maximum trie has 513 states. Matches overlap and include suffix patterns.

Output is one signed 64-bit little-endian occurrence count per pattern in input order. The return value is the output byte count, at most 128 bytes. Malformed input returns `-1`; null or short output returns `-2`; errors write no bytes. Maximum valid and parseable input lengths are 786 and 787 signed 64-bit words. The fixed workspace budget is 49,152 bytes, covering the i64-backed fixed tables in Elisa and Mojo.

The primary oracle builds failure links by breadth-first traversal, accumulates visits to states reached during scanning, and propagates counts to failure parents in reverse breadth-first order. The independent oracle compares each pattern directly at every possible text offset.

## Provenance

The algorithm was independently written from the failure-link and occurrence-count descriptions in [CP-Algorithms' Aho–Corasick article](https://cp-algorithms.com/string/aho_corasick.html) and [OI Wiki's Aho–Corasick article](https://oi-wiki.org/string/ac-automaton/). The OI Wiki description specifically aggregates text-state visits along failure links. No external source code or prose was copied.

## Ports

| Language | Source |
| --- | --- |
| C | [`aho_corasick_failure_tree_counts.c`](../../../c/a/aho_corasick_failure_tree_counts.c) |
| C3 | [`aho_corasick_failure_tree_counts.c3`](../../../c3/a/aho_corasick_failure_tree_counts.c3) |
| C++ | [`aho_corasick_failure_tree_counts.cpp`](../../../cpp/a/aho_corasick_failure_tree_counts.cpp) |
| Elisa | [`aho_corasick_failure_tree_counts.elisa`](../../../elisa/a/aho_corasick_failure_tree_counts.elisa) |
| Mojo | [`aho_corasick_failure_tree_counts.mojo`](../../../mojo/a/aho_corasick_failure_tree_counts.mojo) |
| Nim | [`aho_corasick_failure_tree_counts.nim`](../../../nim/a/aho_corasick_failure_tree_counts.nim) |
| Odin | [`aho_corasick_failure_tree_counts.odin`](../../../odin/a/aho_corasick_failure_tree_counts.odin) |
| Rust | [`aho_corasick_failure_tree_counts.rs`](../../../rust/a/aho_corasick_failure_tree_counts.rs) |
| V | [`aho_corasick_failure_tree_counts.v`](../../../v/a/aho_corasick_failure_tree_counts.v) |
| Zig | [`aho_corasick_failure_tree_counts.zig`](../../../zig/a/aho_corasick_failure_tree_counts.zig) |

Workload and ABI cases are in [`workload.json`](workload.json). Static inventory checks are in [`verify_aho_corasick_failure_tree_counts_package.py`](../../verify_aho_corasick_failure_tree_counts_package.py).
