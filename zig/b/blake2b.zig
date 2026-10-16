const MAX_INPUT: usize = 4096;
const BLOCK_BYTES: usize = 128;
const IV = [_]u64{
    0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
    0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179,
};
const SIGMA = [_]u8{
    0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
    14,10,4,8,9,15,13,6,1,12,0,2,11,7,5,3,
    11,8,12,0,5,2,15,13,10,14,3,6,7,1,9,4,
    7,9,3,1,13,12,11,14,2,6,5,10,4,0,15,8,
    9,0,5,7,2,4,10,15,14,1,11,12,6,8,3,13,
    2,12,6,10,0,11,8,3,4,13,7,5,15,14,1,9,
    12,5,1,15,14,13,4,10,0,7,6,3,9,2,8,11,
    13,11,7,14,12,1,3,9,5,0,15,4,8,6,2,10,
    6,15,14,9,11,3,0,8,12,2,13,7,1,4,10,5,
    10,2,8,4,7,6,1,5,15,11,9,14,3,12,13,0,
};

fn rotr64(value: u64, amount: u32) u64 {
    const right: u6 = @intCast(amount);
    const left: u6 = @intCast(64 - amount);
    return (value >> right) | (value << left);
}
fn mix(v: *[16]u64, a: usize, b: usize, c: usize, d: usize, x: u64, y: u64) void {
    v[a] = v[a] +% v[b] +% x;
    v[d] = rotr64(v[d] ^ v[a], 32);
    v[c] +%= v[d];
    v[b] = rotr64(v[b] ^ v[c], 24);
    v[a] = v[a] +% v[b] +% y;
    v[d] = rotr64(v[d] ^ v[a], 16);
    v[c] +%= v[d];
    v[b] = rotr64(v[b] ^ v[c], 63);
}
fn loadLe64(block: *[BLOCK_BYTES]u8, position: usize) u64 {
    var value: u64 = 0;
    for (0..8) |i| value |= @as(u64, block[position + i]) << @intCast(8 * i);
    return value;
}
fn compress(h: *[8]u64, block: *[BLOCK_BYTES]u8, counter: u64, last: bool) void {
    var m: [16]u64 = undefined;
    var v: [16]u64 = undefined;
    for (&m) |*word| word.* = 0;
    for (&v) |*word| word.* = 0;
    for (0..16) |i| m[i] = loadLe64(block, i * 8);
    for (0..8) |i| { v[i] = h[i]; v[i + 8] = IV[i]; }
    v[12] ^= counter;
    if (last) v[14] = ~v[14];
    for (0..12) |round| {
        const offset = (round % 10) * 16;
        mix(&v,0,4,8,12,m[@intCast(SIGMA[offset])],m[@intCast(SIGMA[offset+1])]);
        mix(&v,1,5,9,13,m[@intCast(SIGMA[offset+2])],m[@intCast(SIGMA[offset+3])]);
        mix(&v,2,6,10,14,m[@intCast(SIGMA[offset+4])],m[@intCast(SIGMA[offset+5])]);
        mix(&v,3,7,11,15,m[@intCast(SIGMA[offset+6])],m[@intCast(SIGMA[offset+7])]);
        mix(&v,0,5,10,15,m[@intCast(SIGMA[offset+8])],m[@intCast(SIGMA[offset+9])]);
        mix(&v,1,6,11,12,m[@intCast(SIGMA[offset+10])],m[@intCast(SIGMA[offset+11])]);
        mix(&v,2,7,8,13,m[@intCast(SIGMA[offset+12])],m[@intCast(SIGMA[offset+13])]);
        mix(&v,3,4,9,14,m[@intCast(SIGMA[offset+14])],m[@intCast(SIGMA[offset+15])]);
    }
    for (0..8) |i| h[i] ^= v[i] ^ v[i + 8];
}

pub export fn blake2b(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (length > MAX_INPUT or (length > 0 and input == null)) return -1;
    for (0..length) |i| if (input[i] < 0 or input[i] > 255) return -1;
    if (output == null or capacity < 64) return -2;
    var h = IV;
    h[0] ^= 0x01010040;
    var block: [BLOCK_BYTES]u8 = undefined;
    for (&block) |*byte| byte.* = 0;
    var consumed: usize = 0;
    var counter: u64 = 0;
    while (length - consumed > BLOCK_BYTES) {
        for (0..BLOCK_BYTES) |i| block[i] = @intCast(input[consumed + i]);
        counter += BLOCK_BYTES;
        compress(&h, &block, counter, false);
        consumed += BLOCK_BYTES;
        for (&block) |*byte| byte.* = 0;
    }
    const remaining = length - consumed;
    for (0..remaining) |i| block[i] = @intCast(input[consumed + i]);
    counter += remaining;
    compress(&h, &block, counter, true);
    for (0..8) |word| {
        for (0..8) |byte| {
            output[word * 8 + byte] = @truncate(h[word] >> @intCast(8 * byte));
        }
    }
    return 64;
}
