# Node neighbors

This benchmark follows the pinned JavaScript graph utility. Edges are undirected; `nodeNeighbors(node)` scans edges in insertion order and returns each adjacent node once, preserving its first encounter order. A self-loop contributes the queried node itself once.

Input is `[edge_count, queried_node, endpoint_0a, endpoint_0b, ...]`, with up to 64 edges and node IDs 0–63. Output is the comma-separated neighbor ID list in encounter order. Invalid input returns `-1`; insufficient output capacity returns `-2`. See `node_neighbors_oracle.py` for the runtime oracle.
