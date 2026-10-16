# Minimum ticket cost

The pinned Python function memoizes a day-indexed dynamic program. On a travel day it chooses among 1-day, 7-day, and 30-day passes; on other days it advances without buying a pass. The year ends after day 365.

## Contract

Input is `[day_count, travel_days..., cost_1_day, cost_7_day, cost_30_day]` as signed 64-bit integers. There are 0 through 365 unique travel days, each in 1..365. Costs are each 0..1,000,000. Output is the minimum total cost. Invalid input returns `-1`; empty travel schedule returns zero.

The contract restricts duplicate days (the source would deduplicate them through a set) to keep the serialized workload canonical. The bounded horizon and nonnegative costs preserve the source's top-down recurrence and make iterative bottom-up ports safe.

See [`workload.json`](workload.json) and the runtime [oracle](../../minimum_tickets_cost_oracle.py). Pinned source: [TheAlgorithms/Python `minimum_tickets_cost.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/minimum_tickets_cost.py).

| Language | Port |
|---|---|
| C | [`c/m/minimum_tickets_cost.c`](../../../c/m/minimum_tickets_cost.c) |
| C3 | [`c3/m/minimum_tickets_cost.c3`](../../../c3/m/minimum_tickets_cost.c3) |
| C++ | [`cpp/m/minimum_tickets_cost.cpp`](../../../cpp/m/minimum_tickets_cost.cpp) |
| Elisa | [`elisa/m/minimum_tickets_cost.elisa`](../../../elisa/m/minimum_tickets_cost.elisa) |
| Nim | [`nim/m/minimum_tickets_cost.nim`](../../../nim/m/minimum_tickets_cost.nim) |
| Odin | [`odin/m/minimum_tickets_cost.odin`](../../../odin/m/minimum_tickets_cost.odin) |
| Rust | [`rust/m/minimum_tickets_cost.rs`](../../../rust/m/minimum_tickets_cost.rs) |
| V | [`v/m/minimum_tickets_cost.v`](../../../v/m/minimum_tickets_cost.v) |
| Zig | [`zig/m/minimum_tickets_cost.zig`](../../../zig/m/minimum_tickets_cost.zig) |
