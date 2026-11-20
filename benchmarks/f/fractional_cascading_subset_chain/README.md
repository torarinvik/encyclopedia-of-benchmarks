# Fractional cascading on a nested catalog chain

This package isolates the explicit iterative-search operation from fractional cascading. Its input is a path of strictly increasing integer catalogs, with each child catalog a subset of its parent, followed by a batch of query keys. For each query and catalog it computes the successor: the least key greater than or equal to the query, or a sentinel when no such key exists.

The primary structure builds bridge tables between adjacent catalogs. A bridge maps each lower-bound slot in a parent catalog to the corresponding lower-bound slot in its child. The nested-set condition means there are no child keys in a gap between consecutive parent keys, so one binary search in the first catalog followed by bridge lookups returns the successors throughout the path. This is a bounded special case of the iterative-search / catalog-graph model in Chazelle and Guibas's [Part I paper](https://doi.org/10.1007/BF01840440) ([author-hosted copy](https://www.cs.princeton.edu/~chazelle/pubs/FractionalCascading1.pdf)); their [Part II paper](https://doi.org/10.1007/BF01840441) develops geometric applications including orthogonal range search.

The contract is `[m,q,(catalog_size,keys...) repeated m times,query_keys...]`. It allows 2–8 catalogs, 1–8 queries, and up to 16 keys per catalog. Keys lie in `[-16,16]`, queries in `[-17,17]`, and every later catalog must be a subset of the previous one. The output is a weighted checksum over successor values, with found keys shifted by 17 and the no-successor sentinel set to 34. Invalid input returns `-1`.

This package measures the catalog-path search primitive directly. It does not claim to implement the general arbitrary catalog graph, range-restricted edges, high-degree techniques, or dynamic updates from the papers. The local [2D orthogonal range reporting profile](../../o/orthogonal_range_reporting_2d/README.md) uses a different geometric API and independently searches each node's y-catalog; this package adds cross-catalog bridge traversal over arbitrary nested lists.

## Language ports

- [C](../../../c/f/fractional_cascading_subset_chain.c)
- [C3](../../../c3/f/fractional_cascading_subset_chain.c3)
- [C++](../../../cpp/f/fractional_cascading_subset_chain.cpp)
- [Elisa](../../../elisa/f/fractional_cascading_subset_chain.elisa)
- [Mojo](../../../mojo/f/fractional_cascading_subset_chain.mojo)
- [Nim](../../../nim/f/fractional_cascading_subset_chain.nim)
- [Odin](../../../odin/f/fractional_cascading_subset_chain.odin)
- [Rust](../../../rust/f/fractional_cascading_subset_chain.rs)
- [V](../../../v/f/fractional_cascading_subset_chain.v)
- [Zig](../../../zig/f/fractional_cascading_subset_chain.zig)

The workload includes ordinary, endpoint, maximum-frame, and malformed cases. The primary [oracle](../../fractional_cascading_subset_chain_oracle.py) builds and follows bridges; the independent [verifier oracle](../../fractional_cascading_subset_chain_verifier_oracle.py) searches every catalog independently. The [static inventory](../../check_fractional_cascading_subset_chain_package.py) checks the package and fixture metadata.
