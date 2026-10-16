package blake2b

import "core:c"

MAX_INPUT :: 4096
BLOCK_BYTES :: 128
IV: [8]u64 = {0x6a09e667f3bcc908,0xbb67ae8584caa73b,0x3c6ef372fe94f82b,0xa54ff53a5f1d36f1,0x510e527fade682d1,0x9b05688c2b3e6c1f,0x1f83d9abfb41bd6b,0x5be0cd19137e2179}
SIGMA: [160]u8 = {
    0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
    14,10,4,8,9,15,13,6,1,12,0,2,11,7,5,3,
    11,8,12,0,5,2,15,13,10,14,3,6,7,1,9,4,
    7,9,3,1,13,12,11,14,2,6,5,10,4,0,15,8,
    9,0,5,7,2,4,10,15,14,1,11,12,6,8,3,13,
    2,12,6,10,0,11,8,3,4,13,7,5,15,14,1,9,
    12,5,1,15,14,13,4,10,0,7,6,3,9,2,8,11,
    13,11,7,14,12,1,3,9,5,0,15,4,8,6,2,10,
    6,15,14,9,11,3,0,8,12,2,13,7,1,4,10,5,
    10,2,8,4,7,6,1,5,15,11,9,14,3,12,13,0
}

rotr64 :: proc "contextless" (value: u64, amount: u32) -> u64 {
    return (value >> amount) | (value << (64 - amount))
}
add64 :: proc "contextless" (a, b: u64) -> u64 {
    low := (a & u64(0xffff_ffff)) + (b & u64(0xffff_ffff))
    high := (a >> 32) + (b >> 32) + (low >> 32)
    return ((high & u64(0xffff_ffff)) << 32) | (low & u64(0xffff_ffff))
}
mix :: proc "contextless" (v: [^]u64, a, b, cc, d: int, x, y: u64) {
    v[a] = add64(add64(v[a], v[b]), x)
    v[d] = rotr64(v[d] ~ v[a], 32)
    v[cc] = add64(v[cc], v[d])
    v[b] = rotr64(v[b] ~ v[cc], 24)
    v[a] = add64(add64(v[a], v[b]), y)
    v[d] = rotr64(v[d] ~ v[a], 16)
    v[cc] = add64(v[cc], v[d])
    v[b] = rotr64(v[b] ~ v[cc], 63)
}
load_le64 :: proc "contextless" (block: [^]u8, position: int) -> u64 {
    value: u64 = 0
    for i := 0; i < 8; i += 1 { value |= u64(block[position + i]) << u32(8 * i) }
    return value
}
compress :: proc "contextless" (h: [^]u64, block: [^]u8, counter: u64, last: bool) {
    m: [16]u64
    v: [16]u64
    for i := 0; i < 16; i += 1 { m[i] = load_le64(block, i * 8) }
    for i := 0; i < 8; i += 1 {
        v[i] = h[i]
        v[i + 8] = IV[i]
    }
    v[12] = v[12] ~ counter
    if last { v[14] = ~v[14] }
    for round := 0; round < 12; round += 1 {
        offset := (round % 10) * 16
        mix(&v[0],0,4,8,12,m[ int(SIGMA[offset]) ],m[ int(SIGMA[offset+1]) ])
        mix(&v[0],1,5,9,13,m[ int(SIGMA[offset+2]) ],m[ int(SIGMA[offset+3]) ])
        mix(&v[0],2,6,10,14,m[ int(SIGMA[offset+4]) ],m[ int(SIGMA[offset+5]) ])
        mix(&v[0],3,7,11,15,m[ int(SIGMA[offset+6]) ],m[ int(SIGMA[offset+7]) ])
        mix(&v[0],0,5,10,15,m[ int(SIGMA[offset+8]) ],m[ int(SIGMA[offset+9]) ])
        mix(&v[0],1,6,11,12,m[ int(SIGMA[offset+10]) ],m[ int(SIGMA[offset+11]) ])
        mix(&v[0],2,7,8,13,m[ int(SIGMA[offset+12]) ],m[ int(SIGMA[offset+13]) ])
        mix(&v[0],3,4,9,14,m[ int(SIGMA[offset+14]) ],m[ int(SIGMA[offset+15]) ])
    }
    for i := 0; i < 8; i += 1 { h[i] = h[i] ~ v[i] ~ v[i + 8] }
}

@(export)
blake2b :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if length > MAX_INPUT || (length > 0 && input == nil) do return -1
    n := int(length)
    for i := 0; i < n; i += 1 { if input[i] < 0 || input[i] > 255 do return -1 }
    if output == nil || capacity < 64 do return -2
    h := IV
    h[0] = h[0] ~ 0x01010040
    block: [BLOCK_BYTES]u8
    consumed := 0
    counter: u64 = 0
    for i := 0; i < BLOCK_BYTES; i += 1 { block[i] = 0 }
    for n - consumed > BLOCK_BYTES {
        for i := 0; i < BLOCK_BYTES; i += 1 { block[i] = u8(input[consumed + i]) }
        counter += u64(BLOCK_BYTES)
        compress(&h[0], &block[0], counter, false)
        consumed += BLOCK_BYTES
        for i := 0; i < BLOCK_BYTES; i += 1 { block[i] = 0 }
    }
    remaining := n - consumed
    for i := 0; i < remaining; i += 1 { block[i] = u8(input[consumed + i]) }
    counter += u64(remaining)
    compress(&h[0], &block[0], counter, true)
    for word := 0; word < 8; word += 1 {
        for byte := 0; byte < 8; byte += 1 { output[word * 8 + byte] = u8(h[word] >> u32(8 * byte)) }
    }
    return 64
}
