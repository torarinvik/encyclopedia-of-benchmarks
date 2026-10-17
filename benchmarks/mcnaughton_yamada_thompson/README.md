# McNaughton–Yamada–Thompson regular-expression matching

This benchmark measures the pinned C implementation's full-string acceptance
result for a small regular-expression language. The source preprocesses
implicit concatenation, builds an expression tree, compiles Thompson's
epsilon-NFA, then simulates that automaton for the complete text.

## Contract

The `i64_array_scalar` input is
`[pattern_length, text_length, pattern_bytes..., text_bytes...]`. Pattern
length is 0–16 bytes and text length is 0–32 bytes. Lengths and byte values
are signed 64-bit integers. Pattern bytes are restricted to ASCII `a`, `b`,
`c`, `(`, `)`, `*`, and `|`. Text bytes may be any ASCII value from 1 through
127; NUL is excluded because the C source treats its input strings as
NUL-terminated.

The empty pattern denotes epsilon and matches only empty text. Nonempty
patterns use this grammar: one or more literals or parenthesized expressions
form an implicit concatenation; `|` separates alternatives; a postfix `*`
applies to one literal or parenthesized expression. Union has lower precedence
than concatenation, and star has the highest precedence. Escapes, empty
groups, empty alternatives, and repeated postfix stars are outside the
contract. A pattern is also limited to at most four NFA fragments, counting
literal, union, and star nodes. Each fragment contributes two states, so at
most eight states can occur; this stays within the pinned implementation's
fixed ten-entry epsilon-closure buffers.

The pinned parser strips the first and last bytes as a group whenever a
substring passed to `buildAST` starts with `(` and ends with `)`, without
checking their matching depth. To preserve that source behavior safely, this
contract rejects a pattern if any recursively parsed substring has an initial
opening parenthesis that closes before its final byte. For example,
`(a)|(b)`, `(a)(b)`, and `((a)|(b))*` are outside this source-compatible
contract.

Return `1` for a full match and `0` for a valid nonmatch. Malformed lengths,
bytes, or patterns return `-1`. The maximum valid input contains 50 values;
51 values are parseable so a trailing-value case can be rejected.

## Pinned source

- TheAlgorithms/C [`mcnaughton_yamada_thompson.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/mcnaughton_yamada_thompson.c), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`

## Workload and oracle

The workload is [`workload.json`](workload.json); the independent parser and
full-match oracle is [`benchmarks/mcnaughton_yamada_thompson_oracle.py`](../mcnaughton_yamada_thompson_oracle.py).
