# Tabu search

This package covers the pinned Python tabu search for a symmetric traveling salesperson problem. It keeps the source's greedy starting tour, ordered 1-1 exchange neighborhood, stable cost sort, symmetric tabu check, size-triggered FIFO removal, and fixed iteration count. The input supplies the graph as a complete undirected weighted graph so every source lookup succeeds.

## Contract

The `i64_array_bytes_output` input is `[city_count, iteration_count, tabu_size, edge_weights...]`. Cities are labeled `a` through `f`. Edge weights follow the pinned text-file line order: `(a,b), (a,c), ... (b,c), ...`; each edge appears once and is undirected. The bounds are 4–6 cities, 0–8 iterations, tabu size 1–3, and positive integer weights 1–99. At four cities, the three distinct interior swaps ensure at least one candidate remains available even with the largest tabu list, which retains at most two moves. The complete graph and weight bounds keep the pinned `10000` sentinel safe and avoid source lookup failures. No randomness is used.

The initial tour starts at `a` and repeatedly selects the first least-cost adjacent unvisited city, where adjacency order follows the listed edges. The source's initial-tour cost calculation, including its sentinel adjustment, is represented by the true closed-tour sum. Each iteration generates swaps by nested traversal of the current tour's interior positions, removes duplicate candidates in first-seen order, and stably sorts them by route cost. It selects the first candidate whose first differing city exchange is absent from the tabu list in both orientations. The selected exchange is appended; when the list length is at least `tabu_size`, its oldest entry is removed. Thus the retained list has at most `tabu_size - 1` entries after an iteration, matching the source. The best tour changes only on strict cost improvement. Output keeps the repeated start city in the best tour because the source removes only the appended neighborhood cost.

Output bytes are little-endian signed 32-bit words: `[tour_length, city_indices..., best_cost]`, with `a=0`. Invalid framing or bounds return `-1`; null output or insufficient capacity returns `-2` and writes nothing. The maximum output is 9 words (36 bytes). The comparison model includes the output byte count and output bytes.

See the [workload](workload.json), [oracle](../../tabu_search_oracle.py), and pinned [`tabu_search`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/tabu_search.py).
