# Prolangs-C `cdecl`: bounded declaration parsing

This package isolates the declarator-precedence portion of the pinned `cdecl` benchmark. It parses one small ANSI-C declaration and returns its canonical type structure. The output preserves the derived operators in identifier-outward order, so the distinction between `int *x[3]` (array of pointers) and `int (*x)[3]` (pointer to array) is explicit.

## Contract

The ABI is `prolangs_c_cdecl` with `i64_array_bytes_output` framing.

- Input is an ASCII declaration encoded as one signed-i64 value per byte.
- The grammar accepts base types `char`, `int`, `float`, `double`, and `void`; identifiers up to 16 characters; up to eight pointer prefixes; fixed array dimensions from 1 through 99; parenthesized declarators; and function suffixes with up to three unnamed primitive or pointer-to-primitive parameters.
- Total input length is 1–96 bytes, with at most 12 derived operators and six levels of declarator parentheses. Arrays of functions, functions returning arrays or functions, and arrays of bare `void` are rejected.
- Output is `[base_type_code, identifier_length, identifier_ascii_bytes..., operator_count, operators...]`. Base codes are `char=1`, `int=2`, `float=3`, `double=4`, `void=5`. Pointer is `[1]`, array is `[2, dimension]`, and function is `[3, arity, (parameter_base_type_code, parameter_pointer_depth)...]`.
- Success returns the output byte length. Invalid input returns -1. Null output or insufficient capacity returns -2 without writing.

The profile leaves out command-language processing, English-to-C declaration generation, casts, qualifiers, storage classes, C++ references/member pointers, named function parameters, and the original help/interactive/file I/O. Its recursive-descent parser is independently written; the shared operation is the bounded grammar and declarator binding semantics, not the original parser implementation.

## Provenance and rights

- Pinned source: [`cdecl.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/cdecl/cdecl.c), with grammar and lexer inputs [`cdgram.y.in`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/cdecl/cdgram.y.in) and [`cdlex.l.in`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/cdecl/cdlex.l.in), from `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.
- The pinned launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/cdecl/info.sh); it compiles `cdecl.c` with `-std=gnu89` and supplies `testset` on stdin.
- The cdecl folder and its `Prolangs-C` parent contain no explicit license grant at the pinned revision. This package does not copy upstream code, comments, grammar text, or generated parser sources, and it does not infer or claim an upstream license. This rights note is not a grant to the pinned source.

## Files

- Independent oracle: [`prolangs_c_cdecl_oracle.py`](../../prolangs_c_cdecl_oracle.py)
- Workload: [`workload.json`](workload.json)

| Language | Port |
|---|---|
| C | [`prolangs_c_cdecl.c`](../../../c/c/prolangs_c_cdecl.c) |
| C3 | [`prolangs_c_cdecl.c3`](../../../c3/c/prolangs_c_cdecl.c3) |
| C++ | [`prolangs_c_cdecl.cpp`](../../../cpp/c/prolangs_c_cdecl.cpp) |
| Elisa | [`prolangs_c_cdecl.elisa`](../../../elisa/c/prolangs_c_cdecl.elisa) |
| Nim | [`prolangs_c_cdecl.nim`](../../../nim/c/prolangs_c_cdecl.nim) |
| Odin | [`prolangs_c_cdecl.odin`](../../../odin/c/prolangs_c_cdecl.odin) |
| Rust | [`prolangs_c_cdecl.rs`](../../../rust/c/prolangs_c_cdecl.rs) |
| V | [`prolangs_c_cdecl.v`](../../../v/c/prolangs_c_cdecl.v) |
| Zig | [`prolangs_c_cdecl.zig`](../../../zig/c/prolangs_c_cdecl.zig) |
