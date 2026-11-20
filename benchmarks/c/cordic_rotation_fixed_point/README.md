# CORDIC rotation in fixed point

This package profiles Volder's circular CORDIC rotation mode. It starts with a unit x-axis vector and uses only integer additions, subtractions, and power-of-two shifts in its coordinate updates. It does not call trigonometric library functions.

## Bounded contract

The `i64_array_bytes_output` input is `[angle_nanoradians, total_stages]`. The angle is an integer in `[-3_141_592_653, 3_141_592_653]`, strictly inside Volder's `[-180°,180°)` domain after nanoradian quantization. `total_stages` is 1 through 16 and counts the initial exact ±90° rotation as stage one.

The fixed-point scale is `Q=1_000_000_000`. Initial registers are `(X,Y,Z)=(Q,0,angle_nanoradians)`. Stage one chooses direction `d=+1` when `Z>=0` and `d=-1` otherwise, rotates `(X,Y)` by exactly the signed quarter turn, and updates `Z := Z-d*1_570_796_327`. Each later stage `j=0..total_stages-2` chooses the same signed-residual direction and applies

    X' = X - d * ashr(Y,j)
    Y' = Y + d * ashr(X,j)
    Z' = Z - d * A[j]

where `A[j]` is `round(atan(2^-j)*Q)`, with the table `[785398163, 463647609, 244978663, 124354995, 62418810, 31239833, 15623729, 7812341, 3906230, 1953123, 976562, 488281, 244141, 122070, 61035]`. `ashr` means signed two's-complement arithmetic shift, equivalently floor division by `2^j`; this makes negative shifts portable across languages. At zero residual the pinned tie direction is `+1`.

The byte-output contract returns three IEEE-754 binary64 words `[X/Q, Y/Q, Z/Q]`, serialized little-endian in exactly 24 bytes (8 bytes per word). The coordinates retain Volder's accumulated gain `K`; there is no gain compensation. A valid call writes exactly 24 bytes and returns 24. Malformed input returns -1 before output checks. For valid input, null output or capacity below 24 returns -2 without writing.

The fixed-point primary reference simulates the registers exactly. The independent reference evaluates the final signed rotation angle and accumulated gain as a real-valued rotation, rather than replaying the integer coordinate recurrence. Both references accept the suite's capacity/null/length arguments and declare a 128-byte workspace bound. The 5e-8 absolute and relative output tolerances cover the bounded per-stage integer-shift truncation. Per-call mutable workspace is capped at 128 bytes; the read-only angle constants are static program data. [`check_inventory.py`](check_inventory.py) statically reviews all ten source paths, inventory metadata, and workload framing/output lengths; it has not been run.

## Provenance and rights

CORDIC was used for discovery through the [NIST DADS CORDIC entry](https://xlinux.nist.gov/dads/HTML/cordic.html). The method is pinned to Jack E. Volder, “The CORDIC Trigonometric Computing Technique,” *IRE Transactions on Electronic Computers* EC-8(3), 330–334 (1959), [DOI 10.1109/TEC.1959.5222693](https://doi.org/10.1109/TEC.1959.5222693). The article specifies the initial ±90° stage, subsequent arctangent rotations, angle-register direction choice, gain, and two's-complement shift behavior. Only the mathematical method is used; source text, code, figures, and example traces are not reused. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the [primary reference](primary_oracle.py), the [independent reference](independent_oracle.py), and [`INVENTORY.json`](INVENTORY.json).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/cordic_rotation_fixed_point.c`](../../../c/c/cordic_rotation_fixed_point.c) |
| C3 | [`c3/c/cordic_rotation_fixed_point.c3`](../../../c3/c/cordic_rotation_fixed_point.c3) |
| C++ | [`cpp/c/cordic_rotation_fixed_point.cpp`](../../../cpp/c/cordic_rotation_fixed_point.cpp) |
| Elisa | [`elisa/c/cordic_rotation_fixed_point.elisa`](../../../elisa/c/cordic_rotation_fixed_point.elisa) |
| Mojo | [`mojo/c/cordic_rotation_fixed_point.mojo`](../../../mojo/c/cordic_rotation_fixed_point.mojo) |
| Nim | [`nim/c/cordic_rotation_fixed_point.nim`](../../../nim/c/cordic_rotation_fixed_point.nim) |
| Odin | [`odin/c/cordic_rotation_fixed_point.odin`](../../../odin/c/cordic_rotation_fixed_point.odin) |
| Rust | [`rust/c/cordic_rotation_fixed_point.rs`](../../../rust/c/cordic_rotation_fixed_point.rs) |
| V | [`v/c/cordic_rotation_fixed_point.v`](../../../v/c/cordic_rotation_fixed_point.v) |
| Zig | [`zig/c/cordic_rotation_fixed_point.zig`](../../../zig/c/cordic_rotation_fixed_point.zig) |
