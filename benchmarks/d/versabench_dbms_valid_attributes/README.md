# VersaBench DIS R-tree attribute validation

This package profiles `validAttributes` from the pinned DIS R-tree database benchmark. The source traverses an attribute linked list in order, rejecting out-of-range attribute codes, out-of-range key values, and null non-key strings.

## Bounded contract

The scalar symbol `versabench_dbms_valid_attributes` accepts `[count, (code,payload)*]` with `count` in 0..51 and exact length `1 + 2*count` (maximum 103, maximum parseable length 104), matching the pinned maximum large-object attribute count. Source attribute codes 0..7 are key fields; codes 8..50 are non-key fields.

For key codes 0..7, `payload` carries the unsigned IEEE-754 binary32 bit pattern in a signed i64 word, constrained to 0..4,294,967,295. The source checks the decoded `float` against ±`FLT_MAX`: all finite binary32 values pass, infinities fail, and NaNs pass because both ordered comparisons are false. For non-key codes 8..50, payload is a bounded pointer-presence tag: 0 models `NULL` and makes the attribute list invalid; 1 models any non-null string pointer and is valid. No string contents are needed because the source only checks pointer nullness.

Return 1 when every attribute is valid, 0 for a source-level invalid attribute (including code outside 0..50), and -1 for malformed framing or a payload outside its tagged representation. Validation is ordered; an invalid code returns 0 before its union payload is interpreted. The empty list returns 1, matching the source's null/empty linked-list traversal. The profile excludes data-object allocation, attribute content, query traversal, and error-message side effects.

## Provenance and rights

Pinned source: [`validAttributes` in `VersaBench/dbms/valid.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/valid.c), with attribute layout/ranges from [`dataObject.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/dataObject.h) and primitive definitions in `dataManagement.h`; repository commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Headers identify M. L. Rivas and `Copyright 1999, Atlantic Aerospace Electronics Corp.`. No explicit redistribution license was found in the pinned directory. The local profile is independently written, preserves the documented validation behavior, and copies no upstream code or comments; see [NOTICE.txt](NOTICE.txt).

Oracle: [`versabench_dbms_valid_attributes_oracle.py`](../../versabench_dbms_valid_attributes_oracle.py). Cases: [workload.json](workload.json). No runtime or compiler verification is claimed.

## Language ports

- C: [../../../c/d/versabench_dbms_valid_attributes.c](../../../c/d/versabench_dbms_valid_attributes.c)
- C3: [../../../c3/d/versabench_dbms_valid_attributes.c3](../../../c3/d/versabench_dbms_valid_attributes.c3)
- C++: [../../../cpp/d/versabench_dbms_valid_attributes.cpp](../../../cpp/d/versabench_dbms_valid_attributes.cpp)
- Elisa: [../../../elisa/d/versabench_dbms_valid_attributes.elisa](../../../elisa/d/versabench_dbms_valid_attributes.elisa)
- Nim: [../../../nim/d/versabench_dbms_valid_attributes.nim](../../../nim/d/versabench_dbms_valid_attributes.nim)
- Odin: [../../../odin/d/versabench_dbms_valid_attributes.odin](../../../odin/d/versabench_dbms_valid_attributes.odin)
- Rust: [../../../rust/d/versabench_dbms_valid_attributes.rs](../../../rust/d/versabench_dbms_valid_attributes.rs)
- V: [../../../v/d/versabench_dbms_valid_attributes.v](../../../v/d/versabench_dbms_valid_attributes.v)
- Zig: [../../../zig/d/versabench_dbms_valid_attributes.zig](../../../zig/d/versabench_dbms_valid_attributes.zig)
