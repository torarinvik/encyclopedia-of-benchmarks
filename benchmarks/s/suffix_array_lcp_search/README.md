# LCP-accelerated suffix-array pattern search

This package implements the chapter's LCP-enhanced binary search over a suffix array from Srinivas Aluru's *Encyclopedia of Algorithms* chapter “Text Indexing,” DOI [`10.1007/978-1-4939-2864-4_422`](https://doi.org/10.1007/978-1-4939-2864-4_422). The chapter gives endpoint/midpoint cases that reuse longest-common-prefix lengths and describes precomputing the midpoint-interval LCP values.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[n,text[n],m,pattern[m]]`, with `1<=n<=32`, `1<=m<=16`, and every symbol in ASCII `0..127`.
- The profile builds the text suffix array and adjacent LCP array, and precomputes LCP values for the binary-search interval tree. It runs LCP-accelerated lower and upper bound searches to locate every suffix beginning with the pattern. A bound reuses the endpoint LCPs; when endpoint LCPs differ, the adjacent LCP range minimum between an endpoint and midpoint determines the source's no-character-comparison branches. At equality, it compares from the larger known prefix length.
- Output is `[occurrence_count,start_0,...]`, with starts emitted in suffix-array lexicographic order. The text-index construction is a bounded insertion sort and direct adjacent-LCP scan; the package makes no construction-time claim. The query recurrence matches the chapter's search cases, with a fixed suffix-prefix comparator for the upper bound. Maximum input is 50 words and output is 264 bytes.
- This profile is distinct from [suffix_array](../suffix_array/README.md), which only returns sorted suffix starts, and from exact brute-force/KMP matching packages, which do not use endpoint LCP reuse. It does not claim a randomized or compressed index, nor a generalized collection index.

## Provenance and rights

Source attribution: Srinivas Aluru, “Text Indexing,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_422`; the LCP binary-search procedure is attributed there to reference [15], Manber and Myers. The chapter and summarized research remain copyrighted. This package is a clean-room implementation and copies no code, prose, or figures; no source-code license is asserted. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary LCP-search oracle](../../suffix_array_lcp_search_oracle.py)
- [independent direct-search verifier](../../suffix_array_lcp_search_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/s/suffix_array_lcp_search.c`](../../../c/s/suffix_array_lcp_search.c) |
| C3 | [`c3/s/suffix_array_lcp_search.c3`](../../../c3/s/suffix_array_lcp_search.c3) |
| C++ | [`cpp/s/suffix_array_lcp_search.cpp`](../../../cpp/s/suffix_array_lcp_search.cpp) |
| Elisa | [`elisa/s/suffix_array_lcp_search.elisa`](../../../elisa/s/suffix_array_lcp_search.elisa) |
| Nim | [`nim/s/suffix_array_lcp_search.nim`](../../../nim/s/suffix_array_lcp_search.nim) |
| Odin | [`odin/s/suffix_array_lcp_search.odin`](../../../odin/s/suffix_array_lcp_search.odin) |
| Rust | [`rust/s/suffix_array_lcp_search.rs`](../../../rust/s/suffix_array_lcp_search.rs) |
| V | [`v/s/suffix_array_lcp_search.v`](../../../v/s/suffix_array_lcp_search.v) |
| Zig | [`zig/s/suffix_array_lcp_search.zig`](../../../zig/s/suffix_array_lcp_search.zig) |
