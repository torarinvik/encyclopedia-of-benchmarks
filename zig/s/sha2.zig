const MAX_MESSAGE_BYTES: usize = 4096;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 4099;
const MAX_PADDED_BYTES: usize = 4224;
const MAX_OUTPUT_BYTES: usize = 64;
const K32 = [_]u32{
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
};
const K64 = [_]u64{
    0x428a2f98d728ae22,0x7137449123ef65cd,0xb5c0fbcfec4d3b2f,0xe9b5dba58189dbbc,
    0x3956c25bf348b538,0x59f111f1b605d019,0x923f82a4af194f9b,0xab1c5ed5da6d8118,
    0xd807aa98a3030242,0x12835b0145706fbe,0x243185be4ee4b28c,0x550c7dc3d5ffb4e2,
    0x72be5d74f27b896f,0x80deb1fe3b1696b1,0x9bdc06a725c71235,0xc19bf174cf692694,
    0xe49b69c19ef14ad2,0xefbe4786384f25e3,0x0fc19dc68b8cd5b5,0x240ca1cc77ac9c65,
    0x2de92c6f592b0275,0x4a7484aa6ea6e483,0x5cb0a9dcbd41fbd4,0x76f988da831153b5,
    0x983e5152ee66dfab,0xa831c66d2db43210,0xb00327c898fb213f,0xbf597fc7beef0ee4,
    0xc6e00bf33da88fc2,0xd5a79147930aa725,0x06ca6351e003826f,0x142929670a0e6e70,
    0x27b70a8546d22ffc,0x2e1b21385c26c926,0x4d2c6dfc5ac42aed,0x53380d13d95b3df,
    0x650a73548baf63de,0x766a0abb3c77b2a8,0x81c2c92e47edaee6,0x92722c851482353b,
    0xa2bfe8a14cf10364,0xa81a664bbc423001,0xc24b8b70d0f89791,0xc76c51a30654be30,
    0xd192e819d6ef5218,0xd69906245565a910,0xf40e35855771202a,0x106aa07032bbd1b8,
    0x19a4c116b8d2d0c8,0x1e376c085141ab53,0x2748774cdf8eeb99,0x34b0bcb5e19b48a8,
    0x391c0cb3c5c95a63,0x4ed8aa4ae3418acb,0x5b9cca4f7763e373,0x682e6ff3d6b2b8a3,
    0x748f82ee5defb2fc,0x78a5636f43172f60,0x84c87814a1f0ab72,0x8cc702081a6439ec,
    0x90befffa23631e28,0xa4506cebde82bde9,0xbef9a3f7b2c67915,0xc67178f2e372532b,
    0xca273eceea26619c,0xd186b8c721c0c207,0xeada7dd6cde0eb1e,0xf57d4f7fee6ed178,
    0x06f067aa72176fba,0x0a637dc5a2c898a6,0x113f9804bef90dae,0x1b710b35131c471b,
    0x28db77f523047d84,0x32caab7b40c72493,0x3c9ebe0a15c9bebc,0x431d67c49c100d4c,
    0x4cc5d4becb3e42b6,0x597f299cfc657e2a,0x5fcb6fab3ad6faec,0x6c44198c4a475817,
};
const H224 = [_]u32{ 0xc1059ed8,0x367cd507,0x3070dd17,0xf70e5939,0xffc00b31,0x68581511,0x64f98fa7,0xbefa4fa4 };
const H256 = [_]u32{ 0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19 };
const H384 = [_]u64{ 0xcbbb9d5dc1059ed8,0x629a292a367cd507,0x9159015a3070dd17,0x152fecd8f70e5939,0x67332667ffc00b31,0x8eb44a8768581511,0xdb0c2e0d64f98fa7,0x47b5481dbefa4fa4 };
const H512 = [_]u64{ 0x6a09e667f3bcc908,0xbb67ae8584caa73b,0x3c6ef372fe94f82b,0xa54ff53a5f1d36f1,0x510e527fade682d1,0x9b05688c2b3e6c1f,0x1f83d9abfb41bd6b,0x5be0cd19137e2179 };
const H512_224 = [_]u64{ 0x8c3d37c819544da2,0x73e1996689dcd4d6,0x1dfab7ae32ff9c82,0x679dd514582f9fcf,0x0f6d2b697bd44da8,0x77e36f7304c48942,0x3f9d85a86a1d36c8,0x1112e6ad91d692a1 };
const H512_256 = [_]u64{ 0x22312194fc2bf72c,0x9f555fa3c84c64c2,0x2393b86b6f53b151,0x963877195940eabd,0x96283ee2a88effe3,0xbe5e1e2553863992,0x2b0199fc2c85b8aa,0x0eb72ddc81c52ca2 };

fn rotr32(x: u32, n: u32) u32 { return (x >> @as(u5, @intCast(n))) | (x << @as(u5, @intCast(32 - n))); }
fn rotr64(x: u64, n: u32) u64 { return (x >> @as(u6, @intCast(n))) | (x << @as(u6, @intCast(64 - n))); }
fn add32(a: u32, b: u32) u32 { return @truncate((@as(u64, a) + @as(u64, b)) & 0xffff_ffff); }
fn add64(a: u64, b: u64) u64 { return @truncate((@as(u128, a) + @as(u128, b)) & 0xffff_ffff_ffff_ffff); }

fn compress32(state: *[8]u32, block: []const u8) void {
    var w = [_]u32{0} ** 64;
    for (0..16) |i| { const p = i * 4; w[i] = (@as(u32, block[p]) << 24) | (@as(u32, block[p + 1]) << 16) | (@as(u32, block[p + 2]) << 8) | block[p + 3]; }
    for (16..64) |i| { const x = w[i - 15]; const y = w[i - 2]; const s0 = rotr32(x, 7) ^ rotr32(x, 18) ^ (x >> 3); const s1 = rotr32(y, 17) ^ rotr32(y, 19) ^ (y >> 10); w[i] = add32(add32(add32(w[i - 16], s0), w[i - 7]), s1); }
    var a=state[0]; var b=state[1]; var c=state[2]; var d=state[3]; var e=state[4]; var f=state[5]; var g=state[6]; var h=state[7];
    for (0..64) |i| { const s1 = rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25); const ch = (e & f) ^ ((~e) & g); const t1 = add32(add32(add32(add32(h, s1), ch), K32[i]), w[i]); const s0 = rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22); const maj = (a & b) ^ (a & c) ^ (b & c); const t2 = add32(s0, maj); h=g;g=f;f=e;e=add32(d,t1);d=c;c=b;b=a;a=add32(t1,t2); }
    state[0]=add32(state[0],a);state[1]=add32(state[1],b);state[2]=add32(state[2],c);state[3]=add32(state[3],d);state[4]=add32(state[4],e);state[5]=add32(state[5],f);state[6]=add32(state[6],g);state[7]=add32(state[7],h);
}

fn compress64(state: *[8]u64, block: []const u8) void {
    var w = [_]u64{0} ** 80;
    for (0..16) |i| { var value: u64 = 0; for (0..8) |j| value = (value << 8) | block[i * 8 + j]; w[i] = value; }
    for (16..80) |i| { const x = w[i - 15]; const y = w[i - 2]; const s0 = rotr64(x, 1) ^ rotr64(x, 8) ^ (x >> 7); const s1 = rotr64(y, 19) ^ rotr64(y, 61) ^ (y >> 6); w[i] = add64(add64(add64(w[i - 16], s0), w[i - 7]), s1); }
    var a=state[0]; var b=state[1]; var c=state[2]; var d=state[3]; var e=state[4]; var f=state[5]; var g=state[6]; var h=state[7];
    for (0..80) |i| { const s1 = rotr64(e, 14) ^ rotr64(e, 18) ^ rotr64(e, 41); const ch = (e & f) ^ ((~e) & g); const t1 = add64(add64(add64(add64(h, s1), ch), K64[i]), w[i]); const s0 = rotr64(a, 28) ^ rotr64(a, 34) ^ rotr64(a, 39); const maj = (a & b) ^ (a & c) ^ (b & c); const t2 = add64(s0, maj); h=g;g=f;f=e;e=add64(d,t1);d=c;c=b;b=a;a=add64(t1,t2); }
    state[0]=add64(state[0],a);state[1]=add64(state[1],b);state[2]=add64(state[2],c);state[3]=add64(state[3],d);state[4]=add64(state[4],e);state[5]=add64(state[5],f);state[6]=add64(state[6],g);state[7]=add64(state[7],h);
}

fn sha2Digest(variant: usize, values: [*]const i64) [64]u8 {
    const sizes = [_]usize{ 28, 32, 48, 64, 28, 32 };
    const message_length: usize = @intCast(values[1]);
    var padded = [_]u8{0} ** MAX_PADDED_BYTES;
    for (0..message_length) |i| padded[i] = @intCast(values[2 + i]);
    padded[message_length] = 0x80;
    var digest = [_]u8{0} ** 64;
    if (variant < 2) {
        var padded_length = message_length + 1;
        while (padded_length % 64 != 56) padded_length += 1;
        padded_length += 8;
        const bit_length: u64 = @as(u64, @intCast(message_length)) * 8;
        for (0..8) |i| padded[padded_length - 1 - i] = @truncate(bit_length >> @intCast(8 * i));
        var state = if (variant == 0) H224 else H256;
        var offset: usize = 0;
        while (offset < padded_length) : (offset += 64) compress32(&state, padded[offset .. offset + 64]);
        for (0..sizes[variant]) |i| digest[i] = @truncate(state[i / 4] >> @as(u5, @intCast(24 - 8 * (i % 4))));
    } else {
        var padded_length = message_length + 1;
        while (padded_length % 128 != 112) padded_length += 1;
        padded_length += 16;
        const bit_length: u64 = @as(u64, @intCast(message_length)) * 8;
        for (0..8) |i| padded[padded_length - 1 - i] = @truncate(bit_length >> @intCast(8 * i));
        var state = switch (variant) { 2 => H384, 3 => H512, 4 => H512_224, else => H512_256 };
        var offset: usize = 0;
        while (offset < padded_length) : (offset += 128) compress64(&state, padded[offset .. offset + 128]);
        for (0..sizes[variant]) |i| digest[i] = @truncate(state[i / 8] >> @as(u6, @intCast(56 - 8 * (i % 8))));
    }
    return digest;
}

pub export fn sha2(input: ?[*]const i64, input_length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (values[0] < 0 or values[0] > 5 or values[1] < 0 or values[1] > MAX_MESSAGE_BYTES) return -1;
    const variant: usize = @intCast(values[0]);
    const message_length: usize = @intCast(values[1]);
    if (input_length != 2 + message_length) return -1;
    for (0..message_length) |i| if (values[2 + i] < 0 or values[2 + i] > 255) return -1;
    const sizes = [_]usize{ 28, 32, 48, 64, 28, 32 };
    const digest_length = sizes[variant];
    if (digest_length > MAX_OUTPUT_BYTES) return -1;
    const out = output orelse return -2;
    if (output_capacity < digest_length) return -2;
    const digest = sha2Digest(variant, values);
    for (0..digest_length) |i| out[i] = digest[i];
    return @intCast(digest_length);
}
