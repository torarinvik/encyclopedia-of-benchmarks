# ISO 10126-2 padding

This benchmark follows the pinned C# `AddPadding`, `RemovePadding`, and `GetPaddingCount` methods. The random fill is supplied in the input so every call has deterministic output; each explicit fill byte is limited to 0–254, matching `RandomNumberGenerator.GetInt32(255)`.

## Contract

- Add mode input is `[0, payload_offset, buffer_length, payload bytes, random-fill bytes]`. It writes `buffer_length - payload_offset - 1` fill bytes, then the final padding-count byte. Remove and count inputs are `[mode, buffer_length, bytes...]`, where mode 1 removes padding and mode 2 returns its count.
- Buffer lengths are 1–64 bytes. Add mode requires `0 <= payload_offset < buffer_length`; its explicit random-fill length is exactly `buffer_length - payload_offset - 1`. Remove and count modes accept a final padding count from 1 through the buffer length. Byte values are 0–255.
- The ABI returns the number of encoded output bytes. Add mode writes the source padding count as the first output byte, followed by the padded buffer; remove mode writes the data prefix; count mode writes one count byte. Invalid input returns `-1`. A null output pointer or insufficient output capacity returns `-2` without writing. The maximum output is 65 bytes, so the declared workspace is 65 bytes.
- The source's empty-input indexing exception is outside the contract; packed inputs must contain an operation and at least one buffer-length value.

The workload covers all three operations, offset and padding boundaries, malformed lengths and byte values, invalid padding counts, and short and exact output capacities. The independent oracle is [`iso10126_d2_padding_oracle.py`](../../iso10126_d2_padding_oracle.py); workload metadata is in [`workload.json`](workload.json).

Run the cross-language verifier with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm iso10126_d2_padding`.

## Pinned source

[TheAlgorithms/C-Sharp `Iso10126D2Padding.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Crypto/Paddings/Iso10126D2Padding.cs), pinned at commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6`.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/i/iso10126_d2_padding.c`](../../../c/i/iso10126_d2_padding.c) |
| C3 | [`c3/i/iso10126_d2_padding.c3`](../../../c3/i/iso10126_d2_padding.c3) |
| C++ | [`cpp/i/iso10126_d2_padding.cpp`](../../../cpp/i/iso10126_d2_padding.cpp) |
| Elisa | [`elisa/i/iso10126_d2_padding.elisa`](../../../elisa/i/iso10126_d2_padding.elisa) |
| Nim | [`nim/i/iso10126_d2_padding.nim`](../../../nim/i/iso10126_d2_padding.nim) |
| Odin | [`odin/i/iso10126_d2_padding.odin`](../../../odin/i/iso10126_d2_padding.odin) |
| Rust | [`rust/i/iso10126_d2_padding.rs`](../../../rust/i/iso10126_d2_padding.rs) |
| V | [`v/i/iso10126_d2_padding.v`](../../../v/i/iso10126_d2_padding.v) |
| Zig | [`zig/i/iso10126_d2_padding.zig`](../../../zig/i/iso10126_d2_padding.zig) |
