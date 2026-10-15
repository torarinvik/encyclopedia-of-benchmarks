package md5

import "core:c"

MD5_SHIFTS :: [64]u32{
    7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22,
    5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20,
    4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23,
    6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21,
}
MD5_K :: [64]u32{
    0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,
    0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,0x6b901122,0xfd987193,0xa679438e,0x49b40821,
    0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,
    0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,
    0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,
    0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,
    0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,
    0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391,
}

md5_add32 :: proc "contextless" (left, right: u32) -> u32 {
    return u32((u64(left) + u64(right)) & 0xffff_ffff)
}

md5_rotate_left :: proc "contextless" (value: u32, amount: u32) -> u32 {
    return (value << amount) | (value >> (32 - amount))
}

md5_byte :: proc "contextless" (input: [^]i64, length, padded_length: int,
                                 bit_length: u64, position: int) -> u32 {
    if position < length do return u32(input[position])
    if position == length do return 0x80
    if position >= padded_length - 8 {
        return u32((bit_length >> u64(8 * (position - (padded_length - 8)))) & 0xff)
    }
    return 0
}

md5_word :: proc "contextless" (input: [^]i64, length, padded_length: int,
                                 bit_length: u64, block_offset, word_index: int) -> u32 {
    value: u32 = 0
    start := block_offset + word_index * 4
    for byte := 0; byte < 4; byte += 1 {
        value |= md5_byte(input, length, padded_length, bit_length, start + byte) << u32(8 * byte)
    }
    return value
}

@(export)
md5 :: proc "c" (input: [^]i64, length: c.size_t,
                  output: [^]u8, capacity: c.size_t) -> i64 {
    if length > 4096 || (length > 0 && input == nil) do return -1
    count := int(length)
    for index := 0; index < count; index += 1 {
        if input[index] < 0 || input[index] > 255 do return -1
    }
    if output == nil || capacity < 16 do return -2

    padded_length := ((count + 8) / 64 + 1) * 64
    bit_length := u64(count) * 8
    h0, h1, h2, h3 := u32(0x67452301), u32(0xefcdab89), u32(0x98badcfe), u32(0x10325476)
    for offset := 0; offset < padded_length; offset += 64 {
        words: [16]u32
        for index := 0; index < 16; index += 1 {
            words[index] = md5_word(input, count, padded_length, bit_length, offset, index)
        }
        a, b, c, d := h0, h1, h2, h3
        for index := 0; index < 64; index += 1 {
            f, g: u32
            if index < 16 {
                f = (b & c) | (~b & d)
                g = u32(index)
            } else if index < 32 {
                f = (d & b) | (~d & c)
                g = u32((5 * index + 1) % 16)
            } else if index < 48 {
                f = b ~ c ~ d
                g = u32((3 * index + 5) % 16)
            } else {
                f = c ~ (b | ~d)
                g = u32((7 * index) % 16)
            }
            total := md5_add32(md5_add32(md5_add32(a, f), MD5_K[index]), words[g])
            previous_d := d
            d = c
            c = b
            b = md5_add32(b, md5_rotate_left(total, MD5_SHIFTS[index]))
            a = previous_d
        }
        h0 = md5_add32(h0, a)
        h1 = md5_add32(h1, b)
        h2 = md5_add32(h2, c)
        h3 = md5_add32(h3, d)
    }
    state := [4]u32{h0, h1, h2, h3}
    for word := 0; word < 4; word += 1 {
        for byte := 0; byte < 4; byte += 1 {
            output[word * 4 + byte] = u8((state[word] >> u32(8 * byte)) & 0xff)
        }
    }
    return 16
}
