# Knapsack profit-scaling FPTAS

This bounded profile implements the Ibarra–Kim profit-scaling approximation scheme described in the Encyclopedia of Algorithms chapter “Knapsack” (DOI suffix 192). It is distinct from this repository's exact 0/1 dynamic programs and branch-and-bound profiles.

## Contract

- Input is `[capacity, n, weight_0, profit_0, ...]`, with capacity 1–100, `n` 1–12, weights 1–100, and positive profits 1–10,000. The input has exactly `2+2n` signed 64-bit values (maximum 26).
- The profile fixes `epsilon=1/2`. It removes items heavier than capacity, sorts the remaining items by decreasing exact profit/weight ratio (ID breaks ties), and computes `U_LP=floor(z_LP)` from the fractional-knapsack relaxation.
- It uses `K=epsilon*U_LP/(2n)=U_LP/(4n)` and scaled profits `floor(p_i/K)=floor(4n*p_i/U_LP)`, then runs DP-Profits to find the greatest feasible scaled-profit total. The DP retains minimum weight for each total; equal-weight ties keep the smaller item bitmask. The selected set's original profit is returned.
- Output is two little-endian signed 64-bit values: `[selected_item_bitmask, original_profit]` (16 bytes). A valid instance with no item fitting returns `[0,0]`.
- Malformed frames/values and a null input return `-1`; a null output or capacity below 16 returns `-2`. Validation precedes output-pointer/capacity checks, and no bytes are written on error.

The fixed epsilon and tie rules make the chapter's scheme deterministic for cross-language comparison. The profile is the base profit-scaling DP scheme; it does not include the chapter's later small/large-item improvement, Lawler's refinement, or a runtime epsilon input.

## Source and implementation boundary

The source description is the supplied Encyclopedia of Algorithms EPUB, “Knapsack,” DOI `10.1007/978-1-4939-2864-4_192`, which summarizes Ibarra and Kim's 1975 scheme. The ports are clean-room implementations of the mathematical procedure; no upstream code is included. See [RIGHTS.md](RIGHTS.md).

`workload.json` contains deterministic examples, malformed and capacity cases. The primary oracle implements profit-DP; the independent verifier oracle enumerates bounded subsets and checks the same scaled-profit objective and tie refinement.

## Ports

The C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig implementations export `knapsack_profit_scaling_fptas` through `i64_array_bytes_output`.
