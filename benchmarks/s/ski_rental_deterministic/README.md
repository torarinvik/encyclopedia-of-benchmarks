# Deterministic ski rental

This profile implements the classical deterministic rent-then-buy strategy
discussed in the chapter. Let `r` be the cost of one rental and `p` the
purchase cost. The strategy rents for `floor(p/r)` trips. If another trip
arrives, it purchases before that trip and uses the owned skis afterward.
This is the standard threshold policy for the model where the horizon is
unknown and a purchase can be made when the next trip is announced.

Input is `[rent_cost, purchase_cost, trip_count]`, where rent cost is 1–32,
purchase cost is 1–64, and the supplied trace contains 0–32 trips. Output has
one action byte per trip: `0` rents, `1` buys and skis, and `2` skis on owned
equipment. The trace length does not affect earlier decisions. Malformed
input returns `-1`; a null output or insufficient capacity returns `-2`
without writes. Maximum output is 32 bytes.

The primary oracle computes the threshold directly. The independent verifier
simulates the rental-spend counter and purchase state. This deterministic
profile does not include randomized threshold distributions or the chapter's
alternate peer-observation models.

Source: Mark S. Manasse, “Ski Rental Problem,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_378`](https://doi.org/10.1007/978-1-4939-2864-4_378).
The package contains no copied book prose, figures, or code; see
[RIGHTS.md](RIGHTS.md).

## Workload and ports

The [workload](workload.json) covers no trips, exact and fractional thresholds,
purchase cheaper than one rental, a short horizon, maximum output, malformed
input, null buffers, and capacity errors.

| Language | Port |
| --- | --- |
| C | [`c/s/ski_rental_deterministic.c`](../../../c/s/ski_rental_deterministic.c) |
| C3 | [`c3/s/ski_rental_deterministic.c3`](../../../c3/s/ski_rental_deterministic.c3) |
| C++ | [`cpp/s/ski_rental_deterministic.cpp`](../../../cpp/s/ski_rental_deterministic.cpp) |
| Elisa | [`elisa/s/ski_rental_deterministic.elisa`](../../../elisa/s/ski_rental_deterministic.elisa) |
| Nim | [`nim/s/ski_rental_deterministic.nim`](../../../nim/s/ski_rental_deterministic.nim) |
| Odin | [`odin/s/ski_rental_deterministic.odin`](../../../odin/s/ski_rental_deterministic.odin) |
| Rust | [`rust/s/ski_rental_deterministic.rs`](../../../rust/s/ski_rental_deterministic.rs) |
| V | [`v/s/ski_rental_deterministic.v`](../../../v/s/ski_rental_deterministic.v) |
| Zig | [`zig/s/ski_rental_deterministic.zig`](../../../zig/s/ski_rental_deterministic.zig) |
