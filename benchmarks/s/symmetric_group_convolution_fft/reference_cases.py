"""Hand-derived probes for the small reference; not a benchmark workload."""

P = 998244353

# Lexicographic S3: 012, 021, 102, 120, 201, 210.
# The two adjacent swaps compose in opposite orders to 120 and 201.
CASES = (
    (1, [7], [11], [77]),
    (3, [0, 0, 1, 0, 0, 0], [0, 1, 0, 0, 0, 0], [0, 0, 0, 1, 0, 0]),
    (3, [0, 1, 0, 0, 0, 0], [0, 0, 1, 0, 0, 0], [0, 0, 0, 0, 1, 0]),
    (3, [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [6, 6, 6, 6, 6, 6]),
    (2, [P - 1, 1], [1, 1], [0, 0]),
    (4, [1] * 24, [1] * 24, [24] * 24),
    (4, [1] + [0] * 23, list(range(24)), list(range(24))),
)
