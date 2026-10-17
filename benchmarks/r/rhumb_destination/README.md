# Rhumb-line destination

This benchmark ports the pinned Rust `rhumb_destination` method. It returns the destination latitude and longitude after a traveled distance and bearing.

## Contract

- The ABI is `float64_slice_io`. Input is exactly `[latitude_deg, longitude_deg, distance_m, bearing_deg]`; all values must be finite. Latitude is bounded to `[-80,80]`, longitude to `[-180,180]`, distance to `[0,300000]` meters, and bearing to `[0,360]` degrees. This keeps the computed latitude within about `±82.7°`, so the source's pole clamp remains inactive and the Mercator terms finite.
- Preserve the source operation order: `del=distance/6371000`, convert to radians, calculate `del_phi=del*cos(theta)`, clamp `phi1+del_phi` to `[-PI/2,PI/2]`, calculate `del_psi`, use `q=del_phi/del_psi` only when `abs(del_psi)>1e-12` and otherwise `cos(phi1)`, then calculate `del_lambda=del*sin(theta)/q` and add it to the starting longitude.
- Return `[destination_latitude_deg,destination_longitude_deg]` with longitude left unnormalized. Success writes two binary64 values and returns 2. Invalid input returns `-1` before output checks; a null output or capacity below two returns `-2` without writes. Comparisons use absolute tolerance `1e-10` degrees and relative tolerance `1e-12`.

The workload covers zero distance, cardinal and diagonal bearings, the near-zero Mercator branch, maximum-distance/latitude limits, an unnormalized longitude, malformed inputs, and ABI errors. See [workload.json](workload.json) and the independent [oracle](../../rhumb_destination_oracle.py).

The source is Rust [`rhumb_destination`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/navigation/rhumbline.rs), pinned at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm rhumb_destination --language rust
python3 benchmarks/run_float64_slice_io.py --algorithm rhumb_destination
python3 benchmarks/verify_float64_slice_io.py --algorithm rhumb_destination --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/r/rhumb_destination.c](../../../c/r/rhumb_destination.c) |
| C3 | [c3/r/rhumb_destination.c3](../../../c3/r/rhumb_destination.c3) |
| C++ | [cpp/r/rhumb_destination.cpp](../../../cpp/r/rhumb_destination.cpp) |
| Elisa | [elisa/r/rhumb_destination.elisa](../../../elisa/r/rhumb_destination.elisa) |
| Nim | [nim/r/rhumb_destination.nim](../../../nim/r/rhumb_destination.nim) |
| Odin | [odin/r/rhumb_destination.odin](../../../odin/r/rhumb_destination.odin) |
| Rust | [rust/r/rhumb_destination.rs](../../../rust/r/rhumb_destination.rs) |
| V | [v/r/rhumb_destination.v](../../../v/r/rhumb_destination.v) |
| Zig | [zig/r/rhumb_destination.zig](../../../zig/r/rhumb_destination.zig) |
