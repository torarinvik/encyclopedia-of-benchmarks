# Long-chain k-th ancestor

Answer batched ancestor queries on a rooted tree. The input is
`[N,Q,parent[1..N-1],(vertex,k)*Q]`, with `1 <= N <= 64`, `1 <= Q <= 32`,
root 0, and parent-before-child vertex IDs. Each query asks for the ancestor
`k` edges above its vertex. If `k` exceeds the vertex depth, its answer is
`-1`. Answers are little-endian signed i64 values in query order.

The primary method combines binary lifting and long-chain decomposition.
After lifting by the greatest power of two at most `k`, it resolves the
remaining distance with the current long-chain position or a flattened table
of ancestors above that chain's head. The OI Wiki method uses O(N log N)
preprocessing and answers each bounded query in O(1). The independent
reference follows parent links directly for each query.

Each chain-head block has `height[head]` entries: offset `s-1` stores the
`s`-th parent of the head for `1 <= s <= height[head]`. The query first checks
`k <= depth[vertex]`, so a valid lookup never requests an ancestor above the
root. If the residual leaves the current chain, its offset is strictly below
the selected power-of-two jump and is covered by the head's block.

This is distinct from [`binary_lifting_kth_ancestor`](../../b/binary_lifting_kth_ancestor/README.md),
which follows all set bits of each query and does not use long-chain head
tables. Source: the [OI Wiki long-chain decomposition article](https://oi-wiki.org/graph/hld/),
which gives the long-chain k-th ancestor method. Its article uses the method
description only; the contract, fixtures, references, and ports here are
clean-room. OI Wiki states its default content terms as CC BY-SA 4.0 and SATA
in its [FAQ](https://oi-wiki.org/intro/faq/).

The function returns the number of output bytes (`8*Q`) on success, `-1` for
malformed input, and `-2` for a null or short output buffer. Errors write no
bytes. Maximum output is 256 bytes and the fixed workspace cap is 16,384
bytes.

| Language | Port |
|---|---|
| C | [c/l/long_chain_kth_ancestor.c](../../../c/l/long_chain_kth_ancestor.c) |
| C3 | [c3/l/long_chain_kth_ancestor.c3](../../../c3/l/long_chain_kth_ancestor.c3) |
| C++ | [cpp/l/long_chain_kth_ancestor.cpp](../../../cpp/l/long_chain_kth_ancestor.cpp) |
| Elisa | [elisa/l/long_chain_kth_ancestor.elisa](../../../elisa/l/long_chain_kth_ancestor.elisa) |
| Mojo | [mojo/l/long_chain_kth_ancestor.mojo](../../../mojo/l/long_chain_kth_ancestor.mojo) |
| Nim | [nim/l/long_chain_kth_ancestor.nim](../../../nim/l/long_chain_kth_ancestor.nim) |
| Odin | [odin/l/long_chain_kth_ancestor.odin](../../../odin/l/long_chain_kth_ancestor.odin) |
| Rust | [rust/l/long_chain_kth_ancestor.rs](../../../rust/l/long_chain_kth_ancestor.rs) |
| V | [v/l/long_chain_kth_ancestor.v](../../../v/l/long_chain_kth_ancestor.v) |
| Zig | [zig/l/long_chain_kth_ancestor.zig](../../../zig/l/long_chain_kth_ancestor.zig) |
