const R1 = [_]u32{ 3, 7, 11, 19 };
const R2 = [_]u32{ 3, 5, 9, 13 };
const R3 = [_]u32{ 3, 9, 11, 15 };
const ORDER3 = [_]usize{ 0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15 };

fn add32(left: u32, right: u32) u32 { return left +% right; }
fn rotateLeft(value: u32, amount: u32) u32 {
    const left: u5 = @intCast(amount);
    const right: u5 = @intCast(32 - amount);
    return (value << left) | (value >> right);
}
fn f(x: u32, y: u32, z: u32) u32 { return (x & y) | (~x & z); }
fn g(x: u32, y: u32, z: u32) u32 { return (x & y) | (x & z) | (y & z); }
fn h(x: u32, y: u32, z: u32) u32 { return x ^ y ^ z; }

fn messageWord(input: [*c]const i64, n: usize, padded: usize, bit_length: u64,
               offset: usize, word_index: usize) u32 {
    var result: u32 = 0;
    const first = offset + word_index * 4;
    for (0..4) |j| {
        const position = first + j;
        var value: u32 = 0;
        if (position < n) {
            value = @intCast(input[position + 1]);
        } else if (position == n) {
            value = 0x80;
        } else if (position >= padded - 8) {
            const shift: u6 = @intCast(8 * (position - (padded - 8)));
            value = @truncate((bit_length >> shift) & 0xff);
        }
        const shift: u5 = @intCast(8 * j);
        result |= value << shift;
    }
    return result;
}

export fn md4_digest(input: [*c]const i64, input_length: usize,
                     output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length == 0 or input_length > 4098) return -1;
    const signed_count = input[0];
    if (signed_count < 0 or signed_count > 4096 or input_length != @as(usize, @intCast(signed_count)) + 1) return -1;
    const n: usize = @intCast(signed_count);
    for (0..n) |i| if (input[i + 1] < 0 or input[i + 1] > 255) return -1;
    if (output == null or output_capacity < 16) return -2;

    const padded = ((n + 8) / 64 + 1) * 64;
    const bit_length: u64 = @as(u64, @intCast(n)) * 8;
    var h0: u32 = 0x67452301;
    var h1: u32 = 0xefcdab89;
    var h2: u32 = 0x98badcfe;
    var h3: u32 = 0x10325476;
    var offset: usize = 0;
    while (offset < padded) : (offset += 64) {
        var words = [_]u32{0} ** 16;
        for (0..16) |i| words[i] = messageWord(input, n, padded, bit_length, offset, i);
        var a = h0;
        var b = h1;
        var c = h2;
        var d = h3;
        for (0..48) |step| {
            const round = step / 16;
            const index = step % 16;
            var mix: u32 = 0;
            var word: usize = 0;
            var shift: u32 = 0;
            var additive: u32 = 0;
            if (round == 0) {
                mix = f(b, c, d); word = index; shift = R1[index & 3];
            } else if (round == 1) {
                mix = g(b, c, d); word = (index & 3) * 4 + index / 4;
                shift = R2[index & 3]; additive = 0x5a827999;
            } else {
                mix = h(b, c, d); word = ORDER3[index];
                shift = R3[index & 3]; additive = 0x6ed9eba1;
            }
            const total = add32(add32(add32(a, mix), words[word]), additive);
            const next_b = add32(b, rotateLeft(total, shift));
            const prior_d = d;
            d = c; c = b; b = next_b; a = prior_d;
        }
        h0 = add32(h0, a); h1 = add32(h1, b); h2 = add32(h2, c); h3 = add32(h3, d);
    }
    const state = [_]u32{ h0, h1, h2, h3 };
    for (0..4) |word| {
        for (0..4) |byte| {
            const shift: u5 = @intCast(8 * byte);
            output[word * 4 + byte] = @truncate(state[word] >> shift);
        }
    }
    return 16;
}
