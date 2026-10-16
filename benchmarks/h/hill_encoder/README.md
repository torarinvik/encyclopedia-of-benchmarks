# Hill encoder

This benchmark ports the pinned C# `HillEncoder.Encode` operation. Input is `[text_length, text_codepoints..., key_00..key_22]`; text is 0–64 uppercase ASCII letters, and each row-major 3×3 key entry is an integer from -2 through 2. The encoder pads with spaces to a multiple of three, multiplies each three-character column vector by the key, and casts each resulting value to a UTF-16 character.

The benchmark returns the resulting character code units as little-endian signed 64-bit integers. The bounded key and text domain keeps every transformed value in the nonnegative 16-bit character range. Invalid input returns -1; insufficient output capacity returns -2. Decode and the source class's Gaussian-elimination dependency are outside this encode-only contract. See the [pinned C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Encoders/HillEncoder.cs).
