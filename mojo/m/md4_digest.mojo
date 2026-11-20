from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn add32(left: UInt32, right: UInt32) -> UInt32:
    return UInt32((UInt64(left) + UInt64(right)) & UInt64(0xFFFF_FFFF))

fn rotate_left(value: UInt32, shift: Int) -> UInt32:
    return (value << shift) | (value >> (32 - shift))

fn choose(x: UInt32, y: UInt32, z: UInt32) -> UInt32:
    return (x & y) | ((~x) & z)

fn majority(x: UInt32, y: UInt32, z: UInt32) -> UInt32:
    return (x & y) | (x & z) | (y & z)

fn parity(x: UInt32, y: UInt32, z: UInt32) -> UInt32:
    return x ^ y ^ z

fn round3_word(index: Int) -> Int:
    let group = index // 4
    let phase = index % 4
    var base = 3
    if group == 0: base = 0
    elif group == 1: base = 2
    elif group == 2: base = 1
    return base + (phase % 2) * 8 + (phase // 2) * 4

fn round_shift(round: Int, index: Int) -> Int:
    let phase = index % 4
    if round == 0:
        if phase == 0: return 3
        elif phase == 1: return 7
        elif phase == 2: return 11
        else: return 19
    elif round == 1:
        if phase == 0: return 3
        elif phase == 1: return 5
        elif phase == 2: return 9
        else: return 13
    else:
        if phase == 0: return 3
        elif phase == 1: return 9
        elif phase == 2: return 11
        else: return 15

fn padded_word(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, padded: Int,
               bit_length: UInt64, offset: Int, word_index: Int) -> UInt32:
    var result: UInt32 = 0
    let first = offset + word_index * 4
    for j in range(4):
        let position = first + j
        var byte: UInt32 = 0
        if position < n:
            byte = UInt32(input[position + 1])
        elif position == n:
            byte = UInt32(0x80)
        elif position >= padded - 8:
            byte = UInt32((bit_length >> UInt64(8 * (position - (padded - 8)))) & UInt64(255))
        result |= byte << (8 * j)
    return result

@export("md4_digest")
fn md4_digest(input: UnsafePointer[Int64, ImmutAnyOrigin], input_length: c_size_t,
              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input_length == 0 or input_length > 4098: return -1
    if input == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    let count = input[0]
    if count < 0 or count > 4096 or input_length != c_size_t(count + 1): return -1
    let n = Int(count)
    for index in range(n):
        if input[index + 1] < 0 or input[index + 1] > 255: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2

    let padded = ((n + 8) // 64 + 1) * 64
    let bit_length = UInt64(n) * UInt64(8)
    var h0: UInt32 = 0x67452301
    var h1: UInt32 = 0xEFCDAB89
    var h2: UInt32 = 0x98BADCFE
    var h3: UInt32 = 0x10325476
    for offset in range(0, padded, 64):
        var words = InlineArray[UInt32, 16](fill=0)
        for index in range(16):
            words[index] = padded_word(input, n, padded, bit_length, offset, index)
        var a = h0
        var b = h1
        var c = h2
        var d = h3
        for step in range(48):
            let round = step // 16
            let j = step % 16
            var mix: UInt32 = 0
            var word_index = 0
            var shift = 0
            var additive: UInt32 = 0
            if round == 0:
                mix = choose(b, c, d)
                word_index = j
                shift = round_shift(round, j)
            elif round == 1:
                mix = majority(b, c, d)
                word_index = (j % 4) * 4 + j // 4
                shift = round_shift(round, j)
                additive = UInt32(0x5A827999)
            else:
                mix = parity(b, c, d)
                word_index = round3_word(j)
                shift = round_shift(round, j)
                additive = UInt32(0x6ED9EBA1)
            total = add32(add32(add32(a, mix), words[word_index]), additive)
            next_b = add32(b, rotate_left(total, shift))
            prior_d = d
            d = c
            c = b
            b = next_b
            a = prior_d
        h0 = add32(h0, a)
        h1 = add32(h1, b)
        h2 = add32(h2, c)
        h3 = add32(h3, d)
    let state = InlineArray[UInt32, 4](h0, h1, h2, h3)
    var staged = InlineArray[UInt8, 16](fill=0)
    for word in range(4):
        for byte in range(4):
            staged[word * 4 + byte] = UInt8((state[word] >> (8 * byte)) & UInt32(255))
    for index in range(16): output[index] = staged[index]
    return 16
