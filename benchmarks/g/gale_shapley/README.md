# Gale–Shapley stable matching

This benchmark computes the proposer-optimal stable matching for two equally sized groups with strict complete preference lists. Each proposer advances through its list until an accepter keeps the proposal; an accepter retains the proposal it ranks above its current match. With complete strict preferences, the result is independent of the order in which free proposers are processed.

## Contract

- The `i64_array_bytes_output` input is `[participant_count, proposer preference rows..., accepter preference rows...]`. Each side has 0 through 5 participants. Every row is a permutation of the opposite side's IDs from 0 through `participant_count - 1`.
- The output contains one byte per proposer. Byte `p` is the ID of the accepter matched to proposer `p`.
- Malformed input or an output buffer smaller than the participant count returns `-2` without writing output.
- The implementation uses fixed arrays, performs O(n²) proposals after O(n²) rank preprocessing, allocates no memory, and does not modify the input.

The five-person bound keeps packed inputs within the shared byte-output harness limit. The C++, C#, Java, Lua, and Nim sources all implement proposer-proposing Gale–Shapley matching. The C# `Accepter` and `Proposer` files define participant state used by that algorithm, not separate algorithms. The Python `gale_shapley_bigraph` source uses the same complete-preference stable-matching contract and is recorded as an alias.

## Workload and run

`workload.json` includes empty and single-participant markets, displacement, the C++ examples, the largest supported market, and malformed preferences. Build with `python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm gale_shapley --language LANGUAGE`, then record with `python3 benchmarks/run_i64_array_bytes_output.py --algorithm gale_shapley`.

## Sources

- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/gale_shapley.cpp)
- [C# GaleShapley](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/StableMarriage/GaleShapley.cs)
- [C# Accepter](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/StableMarriage/Accepter.cs)
- [C# Proposer](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/StableMarriage/Proposer.cs)
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/GaleShapley.java)
- [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/misc/stable_marriage/gale_shapley.lua)
- [Nim](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/stable_marriage/gale_shapley.nim)
- [Python bipartite-graph filename](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/gale_shapley_bigraph.py)
