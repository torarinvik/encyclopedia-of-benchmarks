# Inverted-list bitvector intersection

Intersect a query's posting lists when each list is represented as a bitmap over
one compact document-ID domain. This is the book's dense-list bitvector method:
AND the query bitvectors, then convert the result bitmap to ascending IDs by a
linear bit scan.

## Contract

The exported `inverted_list_bitvector_intersection` function uses the
`i64_array_bytes_output` ABI. Its input is
`[domain_size, list_count, list_0_words..., list_1_words..., ...]`:

- `1 <= domain_size <= 1024`; document IDs are `0..domain_size-1`.
- `1 <= list_count <= 16`.
- Each list has `ceil(domain_size / 64)` signed 64-bit words, stored in
  list-major order. Each word is interpreted as its unsigned 64-bit bit
  pattern; bit `r` of word `w` represents document ID `64*w+r`.
- The final word's bits outside the domain must be zero.
- The packed input has exactly `2 + list_count * ceil(domain_size / 64)` values,
  at most 258.

The output is `[count, document_id_0, ...]` as little-endian signed 64-bit
integers. IDs are ascending and occur once, including when an ID belongs to
every input list. An empty intersection is the one-value output `[0]`. The
function returns output bytes written, `-1` for invalid input, and `-2` for a
null output pointer or capacity smaller than the actual encoded result. Errors
leave the output untouched. The maximum output buffer is 8,200 bytes.

The operation ANDs corresponding words across all lists, then linearly scans
the result bits in increasing document-ID order. A bounded result staging array
allows capacity validation before any output write. Maximum scratch is 8,320
bytes: sixteen intersection words and 1,024 result IDs. For domain size `D`,
`Q` lists, and `W=ceil(D/64)` words per list, the method takes
`O(QW + D)` time and `O(W + D)` scratch.

## Distinction and source

The local [`sorted_arrays_intersection`](../sorted_arrays_intersection/README.md)
and [`intersection_of_two_arrays`](../intersection_of_two_arrays/README.md)
advance cursors through sorted value arrays. This profile operates on dense
bitvectors and uses word-wise AND followed by bitmap-to-list conversion; it is
not a wrapper around either merge. Local rank/select packages answer queries on
one bitmap representation; they do not intersect multiple posting bitvectors.

Chapter 628, “Intersections of Inverted Lists,” describes representing each
posting list as a same-domain bitvector, combining query lists with bitwise
AND, and converting the result. It expressly permits a linear scan of the bits
in each word for conversion. The ports follow that described scan and do not
use a source-code implementation. See [RIGHTS.md](RIGHTS.md).

## Workload and ports

[`workload.json`](workload.json) covers one-list behavior, empty and full
intersections, IDs shared by several lists, word and high-bit boundaries,
non-word-aligned domains, invalid padding, null output, and short capacity.
[`primary_oracle.py`](primary_oracle.py) converts bitmaps to sets before
intersecting; [`independent_oracle.py`](independent_oracle.py) checks every
document ID directly. [`verify_workload.py`](verify_workload.py) checks only
metadata, fixtures, and file inventory. All ten source paths are in
[`INVENTORY.md`](INVENTORY.md). The shared
`i64_array_bytes_output` runner and verifier are wired to the primary and
independent oracles; those suites have not been run.
