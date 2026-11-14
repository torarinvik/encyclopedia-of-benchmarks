# Iterative-deepening A* on a directed graph

This draft benchmarks IDA*: repeated depth-first searches limited by
`distance_so_far + heuristic`, raising the threshold to the least exceeded
value after an unsuccessful pass. It differs from [`iddfs`](../iddfs/README.md),
which deepens by path length, and [`astar`](../../a/astar/README.md), which
maintains a best-first frontier.

## Draft contract

The intended ABI is `i64_array_scalar`, symbol `ida_star_graph`. Input is
`[n,m,start,goal,heuristic[n],(from,to)[m]]`: a directed simple graph with unit
edge costs, `1 <= n <= 12`, `0 <= m <= 48`, zero-based vertices, no self-loops,
and no duplicate arcs. Heuristics are integers in `0..n-1`, the goal heuristic
is zero, and each arc must satisfy `h[from] <= 1 + h[to]`. The latter rule
ensures admissibility for vertices that can reach the goal. On valid input,
return the shortest distance, or `-1` if the goal is unreachable. Malformed or
null input returns `INT64_MIN`.

Each DFS pass avoids vertices already on its current path, and neighbors are
visited by ascending vertex number. The initial threshold is `h[start]`; the
next is the smallest rejected `g+h`. In the worst case IDA* explores
exponentially many simple paths; this dense-adjacency draft uses O(n²) storage
plus O(n) recursion. The primary reference is Richard E. Korf's
[1985 IJCAI paper](https://ijcai.org/proceedings/1985/208); only the algorithm
description was consulted, and no paper code or text was copied.
See [RIGHTS.md](RIGHTS.md) for the provenance note.

## Status

Independently written [C](../../../c/i/ida_star_graph.c),
[C++](../../../cpp/i/ida_star_graph.cpp),
[Rust](../../../rust/i/ida_star_graph.rs),
[C3](../../../c3/i/ida_star_graph.c3),
[Nim](../../../nim/i/ida_star_graph.nim), [Odin](../../../odin/i/ida_star_graph.odin),
[Zig](../../../zig/i/ida_star_graph.zig), [V](../../../v/i/ida_star_graph.v),
[Mojo](../../../mojo/i/ida_star_graph.mojo), and
[Elisa](../../../elisa/i/ida_star_graph.elisa) drafts are present, along with a
[breadth-first reference](../../i/ida_star_graph_oracle.py). A
[workload draft](workload.json) and scalar runner/verifier registration are
present, along with a [static inventory checker](check_inventory.py). Verifier
source includes maximum-size and oversized frames, plus
bounded generated directed graphs with zero and nonzero consistent heuristics,
checked against BFS. The workload also
specifies cycles and a longer branch encountered before the shortest path.
Nothing has been
compiled or run.
