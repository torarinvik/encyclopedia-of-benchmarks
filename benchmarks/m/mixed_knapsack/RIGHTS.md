# Rights and provenance

The mixed item-type method is based on the “Mixed Knapsack” section of
CP-Algorithms' [`Knapsack Problem`](https://cp-algorithms.com/dynamic_programming/knapsack.html#mixed-knapsack),
published under CC BY-SA 4.0. Only the high-level recurrence choices were
consulted; no implementation code or article prose was copied.

All package implementations and fixtures are clean-room. The primary uses
descending updates for single-use items, ascending updates for unlimited
items, and binary grouping for bounded items. The independent reference uses
a separate prior-row copy-count recurrence for every item mode.
