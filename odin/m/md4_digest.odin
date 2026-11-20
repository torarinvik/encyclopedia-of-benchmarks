package md4_digest

import "core:c"

MD4_R1 :: [4]u32{3, 7, 11, 19}
MD4_R2 :: [4]u32{3, 5, 9, 13}
MD4_R3 :: [4]u32{3, 9, 11, 15}
MD4_ORDER3 :: [16]u32{0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15}

md4_rotl :: proc "contextless" (x: u32, shift: u32) -> u32 {
    return (x << shift) | (x >> (32 - shift))
}
md4_f :: proc "contextless" (x, y, z: u32) -> u32 { return (x & y) | (~x & z) }
md4_g :: proc "contextless" (x, y, z: u32) -> u32 { return (x & y) | (x & z) | (y & z) }
md4_h :: proc "contextless" (x, y, z: u32) -> u32 { return x ^ y ^ z }

md4_word :: proc "contextless" (input: [^]i64, n, padded: int,
                                bit_length: u64, offset, word_index: int) -> u32 {
    value: u32 = 0
    start := offset + word_index * 4
    for byte := 0; byte < 4; byte += 1 {
        position := start + byte
        part: u32 = 0
        if position < n {
            part = u32(input[position + 1])
        } else if position == n {
            part = 0x80
        } else if position >= padded - 8 {
            part = u32((bit_length >> u64(8 * (position - (padded - 8)))) & 0xff)
        }
        value |= part << u32(8 * byte)
    }
    return value
}

@(export)
md4_digest :: proc "c" (input: [^]i64, input_length: c.size_t,
                         output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || input_length < 1 || input_length > 4098 do return -1
    count := input[0]
    if count < 0 || count > 4096 || input_length != c.size_t(count + 1) do return -1
    n := int(count)
    for i := 0; i < n; i += 1 {
        if input[i + 1] < 0 || input[i + 1] > 255 do return -1
    }
    if output == nil || capacity < 16 do return -2

    padded := ((n + 8) / 64 + 1) * 64
    bit_length := u64(n) * 8
    h0, h1, h2, h3 := u32(0x67452301), u32(0xefcdab89), u32(0x98badcfe), u32(0x10325476)
    for offset := 0; offset < padded; offset += 64 {
        words: [16]u32
        for i := 0; i < 16; i += 1 { words[i] = md4_word(input, n, padded, bit_length, offset, i) }
        a, b, c, d := h0, h1, h2, h3
        for step := 0; step < 48; step += 1 {
            round, index := step / 16, step % 16
            mix, word, shift, additive: u32
            if round == 0 {
                mix = md4_f(b, c, d); word = u32(index); shift = MD4_R1[index % 4]; additive = 0
            } else if round == 1 {
                mix = md4_g(b, c, d); word = u32((index % 4) * 4 + index / 4)
                shift = MD4_R2[index % 4]; additive = 0x5a827999
            } else {
                mix = md4_h(b, c, d); word = MD4_ORDER3[index]
                shift = MD4_R3[index % 4]; additive = 0x6ed9eba1
            }
            next_b := b + md4_rotl(a + mix + words[word] + additive, shift)
            prior_d := d
            d = c; c = b; b = next_b; a = prior_d
        }
        h0 += a; h1 += b; h2 += c; h3 += d
    }
    state := [4]u32{h0, h1, h2, h3}
    for word := 0; word < 4; word += 1 {
        for byte := 0; byte < 4; byte += 1 {
            output[word * 4 + byte] = u8((state[word] >> u32(8 * byte)) & 0xff)
        }
    }
    return 16
}
