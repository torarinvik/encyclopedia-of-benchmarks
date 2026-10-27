# Greedy-2 single-minded multi-unit combinatorial auction

This package implements the chapter-defined Greedy-2 primal-dual allocation routine from “Utilitarian Mechanism Design for Single-Minded Agents,” DOI [`10.1007/978-1-4939-2864-4_454`](https://doi.org/10.1007/978-1-4939-2864-4_454), Figure 3. Each bidder requests one nonempty set of goods and has a positive value. The algorithm initializes item prices, repeatedly selects the bidder with maximum value-to-price-sum ratio, raises prices on the selected bundle, and stops at the chapter's dual threshold.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[item_count,bidder_count, capacities[item_count], (value,bundle_mask)[bidder_count]]`. Bundle bit `e` denotes item `e`; all bundle masks must be nonzero.
- `2<=item_count<=6`, `1<=bidder_count<=12`, capacities `b_e` are integers in `[1,8]`, and values are integers in `[1,100]`. The chapter's `B` is `min_e b_e`; `m` is the number of items. Input has at most 32 signed-i64 words.
- Prices start at `y_e=1/b_e`. At each step, choose the remaining bidder maximizing `value_i / sum_{e in bundle_i} y_e`, with ties resolved by lower input index. For each requested item, update `y_e *= (e^B m)^(1/b_e)`. Stop once `sum_e b_e y_e >= e^B m` or all bidders are selected.
- Output is `[selected_count, bidder_id...]` in selection order, encoded as little-endian signed-i64 words. Maximum output is 104 bytes. The transcendental updates use IEEE-754 binary64; fixture values avoid near-tie comparisons.
- The profile covers the CA allocation loop only. It does not evaluate payments, prove truthfulness experimentally, or implement the more general UFP path-finding variant in Figure 2.

## Provenance and rights

Source: Piotr Krysta and Berthold Vöcking, “Utilitarian Mechanism Design for Single-Minded Agents,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_454`, Figure 3 and its surrounding definitions. The chapter is copyrighted and carries no source-code license. This is an independently written implementation of the stated mathematical loop; it copies no source code, figure, or prose. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary oracle](../../truthful_multiunit_ca_greedy2_oracle.py)
- [independent verifier oracle](../../truthful_multiunit_ca_greedy2_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/g/truthful_multiunit_ca_greedy2.c`](../../../c/g/truthful_multiunit_ca_greedy2.c) |
| C3 | [`c3/g/truthful_multiunit_ca_greedy2.c3`](../../../c3/g/truthful_multiunit_ca_greedy2.c3) |
| C++ | [`cpp/g/truthful_multiunit_ca_greedy2.cpp`](../../../cpp/g/truthful_multiunit_ca_greedy2.cpp) |
| Elisa | [`elisa/g/truthful_multiunit_ca_greedy2.elisa`](../../../elisa/g/truthful_multiunit_ca_greedy2.elisa) |
| Nim | [`nim/g/truthful_multiunit_ca_greedy2.nim`](../../../nim/g/truthful_multiunit_ca_greedy2.nim) |
| Odin | [`odin/g/truthful_multiunit_ca_greedy2.odin`](../../../odin/g/truthful_multiunit_ca_greedy2.odin) |
| Rust | [`rust/g/truthful_multiunit_ca_greedy2.rs`](../../../rust/g/truthful_multiunit_ca_greedy2.rs) |
| V | [`v/g/truthful_multiunit_ca_greedy2.v`](../../../v/g/truthful_multiunit_ca_greedy2.v) |
| Zig | [`zig/g/truthful_multiunit_ca_greedy2.zig`](../../../zig/g/truthful_multiunit_ca_greedy2.zig) |
