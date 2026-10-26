# Technology mapping by minimum-area tree covering

This package implements the exact minimum-area tree-covering dynamic program described in Kurt Keutzer and Kaushik Ravindran's *Encyclopedia of Algorithms* chapter “Technology Mapping,” DOI [`10.1007/978-1-4939-2864-4_420`](https://doi.org/10.1007/978-1-4939-2864-4_420). The subject is an ordered tree of primary-input leaves, unary inverters, and binary NAND2 gates. A small technology library supplies area costs for five structural patterns.

## Bounded contract

- ABI: `i64_array_bytes_output`; input layout is `[n, cost_INV, cost_NAND2, cost_NAND2_INV_LEFT, cost_NAND2_INV_RIGHT, cost_NAND2_INV_BOTH, (kind,left,right)*]`.
- `1 <= n <= 31`. Nodes are numbered in preorder, root is node 0, and every non-root node has exactly one parent. Kinds are `0` primary input, `1` inverter with `left` as its child and `right=-1`, or `2` NAND2 with two ordered children. Each child ID is greater than its parent ID.
- Pattern IDs and costs correspond to the library patterns: `0` INV; `1` NAND2; `2` NAND2 with an INV on its left input; `3` NAND2 with an INV on its right input; `4` NAND2 with INV gates on both inputs. A cost of `-1` disables a pattern; otherwise area is an integer in `1..1,000,000`. Cutpoint inputs of a matched pattern are covered recursively by their own minimum-area tree covers.
- The dynamic program minimizes the sum of library pattern areas. Equal-area choices use the lowest pattern ID. Output is `[minimum_area, pattern_for_node_0,...,pattern_for_node_(n-1)]`; primary inputs are `-1`, and a gate absorbed inside an ancestor pattern is `-2`. This makes the selected cover observable.
- A subject tree with no valid cover under the supplied library returns `-1`. Invalid input returns `-1`; null or short output returns `-2` without writes. Maximum input is 99 words and output is 256 bytes.
- This is the chapter's exact tree-covering core on a restricted ordered gate/pattern family. It does not implement DAGON's DAG-to-forest partition heuristic, Boolean matching, delay/power objectives, or technology-library parsing.

## Provenance and rights

Source attribution: Kurt Keutzer and Kaushik Ravindran, “Technology Mapping,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_420`. The chapter and summarized research remain copyrighted. This clean-room package copies no source code, prose, or figures and asserts no source-code license. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary bottom-up oracle](../../technology_mapping_minimum_area_tree_cover_oracle.py)
- [independent recursive verifier oracle](../../technology_mapping_minimum_area_tree_cover_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/t/technology_mapping_minimum_area_tree_cover.c`](../../../c/t/technology_mapping_minimum_area_tree_cover.c) |
| C3 | [`c3/t/technology_mapping_minimum_area_tree_cover.c3`](../../../c3/t/technology_mapping_minimum_area_tree_cover.c3) |
| C++ | [`cpp/t/technology_mapping_minimum_area_tree_cover.cpp`](../../../cpp/t/technology_mapping_minimum_area_tree_cover.cpp) |
| Elisa | [`elisa/t/technology_mapping_minimum_area_tree_cover.elisa`](../../../elisa/t/technology_mapping_minimum_area_tree_cover.elisa) |
| Nim | [`nim/t/technology_mapping_minimum_area_tree_cover.nim`](../../../nim/t/technology_mapping_minimum_area_tree_cover.nim) |
| Odin | [`odin/t/technology_mapping_minimum_area_tree_cover.odin`](../../../odin/t/technology_mapping_minimum_area_tree_cover.odin) |
| Rust | [`rust/t/technology_mapping_minimum_area_tree_cover.rs`](../../../rust/t/technology_mapping_minimum_area_tree_cover.rs) |
| V | [`v/t/technology_mapping_minimum_area_tree_cover.v`](../../../v/t/technology_mapping_minimum_area_tree_cover.v) |
| Zig | [`zig/t/technology_mapping_minimum_area_tree_cover.zig`](../../../zig/t/technology_mapping_minimum_area_tree_cover.zig) |
