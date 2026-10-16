# Normalized Feistel cipher block core

This benchmark is a portable normalized variant of the pinned C# `FeistelCipher` cipher, exposed as one 64-bit block operation; it is not claimed to match the C# runtime’s out-of-range floating-point conversion behavior exactly. The source uses a concrete 32-round Feistel structure, splitting a block into 32-bit halves. It is distinct from DES: the round function here is a custom arithmetic transform, not DES permutations and S-boxes.

Input is `[mode, key, block]`. `mode=0` encrypts and `mode=1` decrypts. `key` is in `1..2^32-1`, and every derived round key must be nonzero because the source uses it as a modulo divisor. The 64-bit block is passed as a signed i64 bit pattern. The result is the output block returned as a signed i64 bit pattern. Invalid arrays return `-1`.

To make the source's uint arithmetic portable, all multiplication and exponentiation are defined modulo `2^32`. Round `r` uses `round_key = wrapping_pow_u32(key, r+2) XOR key`. The source's inner block modification performs 32 iterations of `block = (((block XOR 0x55555555) * block) modulo 2^32) modulo round_key; block = block XOR round_key`. The outer 32 Feistel rounds use the source's left/right update order; decryption applies those rounds in reverse.

This is a normalized Feistel variant rather than a bit-for-bit port of the source's key schedule. Since `Math.Pow` produces `double`, every possible key leads to an out-of-range `uint` conversion somewhere in 32 rounds: key 1 produces a zero round key, while keys 2 and above eventually exceed the `uint` range. The benchmark therefore defines the intended fixed-width wrapping behavior explicitly.

The source text wrapper splits ASCII bytes into big-endian 8-byte blocks and right-pads the final partial block with zero bytes. Its decoder omits every zero byte, so that wrapper cannot preserve embedded or trailing NUL bytes. This contract exposes the reversible block core directly; it does not include lossy text padding/stripping.

## Pinned source

[TheAlgorithms/C-Sharp `FeistelCipher.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Encoders/FeistelCipher.cs), commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6`.
