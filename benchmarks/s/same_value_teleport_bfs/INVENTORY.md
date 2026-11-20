# Package inventory

- Algorithm: `same_value_teleport_bfs`
- ABI: `i64_array_scalar`
- Status: ten native ports, primary and independent references, workload,
  catalog, and scalar-suite integration complete; no executable checks run.
- Distinguishing operation: BFS over adjacent-index edges and implicit
  equal-value cliques, with each value group consumed after its first scan.
- Maximum valid input: 65 signed 64-bit words.
- Workspace: 3,072 bytes.
- Sources: LeetCode 1345 (discovery/transition) and CP-Algorithms BFS method.
