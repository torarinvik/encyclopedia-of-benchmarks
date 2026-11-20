# JSON Pointer evaluation over a bounded value tree

Resolve an RFC 6901 pointer against a small, already-parsed JSON value tree.
The benchmark measures pointer token scanning and decoding plus node lookup.
The document is supplied as a flat node table so the kernel does not include a
language-specific JSON parser.

## Contract

- ABI: `i64_array_scalar`.
- Input begins `[node_count, root_id, pointer_length, pointer_ascii_bytes...]`.
- It is followed by `node_count` fixed 21-word records:
  `[kind, parent_id, key_length, key_ascii[16], array_index, payload]`.
- Kinds are `0=object`, `1=array`, and `2=opaque scalar leaf`. For an object
  child, `key_ascii` stores its ASCII member name and `array_index` is `-1`.
  For an array child, `key_length` is zero and `array_index` is its index.
  The root has parent `-1`, empty key, and index `-1`. Unused key slots are
  zero. Array children must have unique contiguous indices starting at zero.
  Object member names may repeat; a pointer to a repeated name is unresolved.
  Scalar payloads are opaque and do not affect the returned node identity.
- Accept `1<=node_count<=32`, `0<=pointer_length<=64`, object keys up to 16
  ASCII characters, and a single rooted tree. The empty pointer selects the
  root; nonempty pointers start with `/`. Each `~1` decodes to `/` and each
  `~0` decodes to `~`; any other tilde escape is malformed. Tokens are applied
  from the root in order. The complete pointer's escapes are validated before
  traversal, so malformed syntax returns `-1` even when an earlier token would
  not resolve. Object lookup compares the decoded token exactly.
  Array tokens are canonical decimal indices (`0` or a nonzero digit followed
  by digits); `-`, leading zeroes, missing children, duplicate object keys,
  and traversal through a scalar fail resolution.
- Return the selected node's table index, `-1` for malformed framing, tree, or
  pointer syntax, and `-2` when a syntactically valid pointer does not resolve
  to exactly one node.
- Maximum valid frame: 739 signed 64-bit words. The parser accepts at most 740
  words so the one-word trailing-frame case can be rejected. The fixed token
  buffer uses 512 bytes of workspace.
- Tree validation takes `O(N^2)` time. Pointer traversal scans at most `N`
  records per token and compares at most `P` token bytes overall, for
  `O(N^2 + NP)` time and `O(P)` auxiliary space, with `N<=32`, `P<=64`.

## Distinction and provenance

This is RFC 6901 pointer evaluation, not JSON parsing or JSONPath query
evaluation. The flat table preserves object/array traversal and escape behavior
while keeping the input representation portable across all ten benchmark
languages. The [RFC 6901 specification](https://www.rfc-editor.org/rfc/rfc6901.html)
is the algorithm contract. It notes that extracted code components must carry
Simplified BSD terms; this package extracts no code component and uses the
standard's behavior only. RosettaCodeData supplied a title for discovery only;
no task page, solution, code, tests, examples, or prose was reused.

[`workload.json`](workload.json) records the bounded ABI and representative
root, object, malformed-escape, and unresolved-pointer cases. The primary
reference scans the flat table directly. Both references and all native ports
validate pointer escapes before traversal. The independent reference builds
parent-child adjacency and splits/decodes the pointer before traversal.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/j/json_pointer_evaluation.c](../../../c/j/json_pointer_evaluation.c) |
| C3 | [c3/j/json_pointer_evaluation.c3](../../../c3/j/json_pointer_evaluation.c3) |
| C++ | [cpp/j/json_pointer_evaluation.cpp](../../../cpp/j/json_pointer_evaluation.cpp) |
| Elisa | [elisa/j/json_pointer_evaluation.elisa](../../../elisa/j/json_pointer_evaluation.elisa) |
| Mojo | [mojo/j/json_pointer_evaluation.mojo](../../../mojo/j/json_pointer_evaluation.mojo) |
| Nim | [nim/j/json_pointer_evaluation.nim](../../../nim/j/json_pointer_evaluation.nim) |
| Odin | [odin/j/json_pointer_evaluation.odin](../../../odin/j/json_pointer_evaluation.odin) |
| Rust | [rust/j/json_pointer_evaluation.rs](../../../rust/j/json_pointer_evaluation.rs) |
| V | [v/j/json_pointer_evaluation.v](../../../v/j/json_pointer_evaluation.v) |
| Zig | [zig/j/json_pointer_evaluation.zig](../../../zig/j/json_pointer_evaluation.zig) |

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks have been run.
