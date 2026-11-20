# Package inventory

- Contract: `i64_array_bytes_output`; input `[count, Scharnagl IDs...]`.
- Valid IDs: 0..959; batch count: 0..960; duplicate IDs are retained.
- Maximum valid/parseable frames: 961/962 i64 words.
- Output: eight ASCII piece letters per ID in file order; maximum 7,680 bytes.
- Errors: -1 malformed input or ID; -2 nonempty null/short output, without writes.
- Primary reference: mixed-radix bishop/queen/knight unranking, then R-K-R fill.
- Independent reference: multiset permutation enumeration, chess-constraint filtering, and reverse ranking.
- Native workspace cap: 192 bytes, excluding caller-owned input/output.
- Native ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Provenance: RosettaGit discovery page, Scharnagl/van Reem numbering reference, and FIDE Chess960 rules; clean-room package.
