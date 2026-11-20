# Finite standard Sturmian word generation

This package builds a finite standard word from a short directive sequence.
It uses the recurrence described in Berstel's survey and does not approximate
an irrational slope with floating-point arithmetic. It measures finite word
construction only; it does not test a supplied word for Sturmian properties or
generate an infinite sequence.

## Contract

The exported symbol is `sturmian_standard_word` in the
`i64_array_bytes_output` family. Input is `[k,d_0,...,d_(k-1)]`. The number of
steps `k` is in `0..4`; if `k=0`, the input is `[0]` and the result is the
single byte `a`. For `k>0`, `d_0` is in `0..2`; each later directive is in
`1..2`. The frame must contain exactly `k+1` signed 64-bit words.

Set `s[-1] = b` and `s[0] = a`. For each directive in order, construct
`s[i+1] = s[i]` repeated `d_i` times, followed by `s[i-1]`. Return `s[k]` as
raw ASCII bytes (`a` and `b`) with no terminator. Invalid input returns `-1`.
A null output or capacity below the completed word length returns `-2` and
writes no bytes. Input validation precedes output checks.

With `|s[-1]|=|s[0]|=1` and all later repeat counts at most two, the maximum
lengths after each of the four steps are 3, 7, 17, and 41. Thus valid input is
at most five words, the parser accepts up to six words to make a trailing-word
error observable, and output is at most 41 bytes. Every native primary uses
three fixed 41-byte word buffers (123 bytes) plus a four-entry i64 directive
array (32 bytes). The 512-byte declared workspace also allows for live lengths,
loop indices, pointers/views, alignment, and ABI-local state across targets;
caller-owned input and output are excluded.

## References and distinction

The primary reference constructs each `s[i+1]` directly from its predecessor
and current word. The independent reference composes letter morphisms
`sigma_d(a)=a^d b` and `sigma_d(b)=a`, applying them from the last directive
back to the first. These produce the same standard word by separate
constructions.

The repository's [`string_fibonacci`](../../f/string_fibonacci/README.md)
computes decimal digits of the integer `F(n)`; its other Fibonacci packages
compute numeric values or encodings. None generates standard binary words
from an arbitrary directive prefix. This profile includes the Fibonacci word
prefix as one directive choice but is not limited to that special case.

The recurrence and directive constraints follow Jean Berstel, “Sturmian
Words, Sturmian Trees and Sturmian Graphs: A Survey on Some Recent Results,”
2007 ([survey PDF](https://www-igm.univ-mlv.fr/~berstel/Exposes/2007-05BerstelCAI.pdf)).
RosettaCodeData's pinned score-24 [popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used for title discovery only.

## Workload and package files

[`workload.json`](workload.json) pins base words, zero and maximum first
directives, a mixed multi-step word, the all-one Fibonacci directive prefix,
maximum-output capacity failure, malformed frames and directives, null input,
and null output. [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py) are the two references.
[`verify_workload.py`](verify_workload.py) reconciles fixtures against both
references; [`check_inventory.py`](check_inventory.py) reviews package files
and native source presence. Neither helper has been run.

## Native ports

| Language | Source |
|---|---|
| C | [`sturmian_standard_word.c`](../../../c/s/sturmian_standard_word.c) |
| C3 | [`sturmian_standard_word.c3`](../../../c3/s/sturmian_standard_word.c3) |
| C++ | [`sturmian_standard_word.cpp`](../../../cpp/s/sturmian_standard_word.cpp) |
| Elisa | [`sturmian_standard_word.elisa`](../../../elisa/s/sturmian_standard_word.elisa) |
| Mojo | [`sturmian_standard_word.mojo`](../../../mojo/s/sturmian_standard_word.mojo) |
| Nim | [`sturmian_standard_word.nim`](../../../nim/s/sturmian_standard_word.nim) |
| Odin | [`sturmian_standard_word.odin`](../../../odin/s/sturmian_standard_word.odin) |
| Rust | [`sturmian_standard_word.rs`](../../../rust/s/sturmian_standard_word.rs) |
| V | [`sturmian_standard_word.v`](../../../v/s/sturmian_standard_word.v) |
| Zig | [`sturmian_standard_word.zig`](../../../zig/s/sturmian_standard_word.zig) |

See [RIGHTS.md](RIGHTS.md) and [INVENTORY.md](INVENTORY.md) for provenance,
scope and the static file list.
