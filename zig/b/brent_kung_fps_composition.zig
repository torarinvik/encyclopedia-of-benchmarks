const modulus: i64 = 998244353;
const max_n: usize = 32;
const max_input: usize = 66;
const max_blocks: usize = 6;
const max_powers: usize = 7;
const Polynomial = [max_n]i64;

fn multiplyTruncated(left: Polynomial, right: Polynomial, n: usize) Polynomial {
    var product: Polynomial = @splat(0);
    for (0..n) |i| {
        for (0..(n - i)) |j| {
            product[i + j] = @mod(product[i + j] + left[i] * right[j], modulus);
        }
    }
    return product;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn brent_kung_fps_composition(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 2 * n) return -1;
    for (0..2 * n) |i| {
        if (input[i + 1] < 0 or input[i + 1] >= modulus) return -1;
    }
    if (input[1 + n] != 0) return -1;
    const bytes = 8 * n;
    if (output_opt == null or capacity < bytes) return -2;

    var block_size: usize = 1;
    while (block_size * block_size < n) : (block_size += 1) {}
    const block_count = (n + block_size - 1) / block_size;
    var powers: [max_powers]Polynomial = [_]Polynomial{@splat(0)} ** max_powers;
    var blocks: [max_blocks]Polynomial = [_]Polynomial{@splat(0)} ** max_blocks;
    var inner: Polynomial = @splat(0);
    for (0..n) |degree| inner[degree] = input[1 + n + degree];
    powers[0][0] = 1;
    const power_end = block_size + 1;
    for (1..power_end) |exponent|
        powers[exponent] = multiplyTruncated(powers[exponent - 1], inner, n);
    for (0..block_count) |block| {
        for (0..block_size) |offset| {
            const coefficient_index = block * block_size + offset;
            if (coefficient_index >= n) break;
            const coefficient = input[1 + coefficient_index];
            for (0..n) |degree| {
                blocks[block][degree] = @mod(
                    blocks[block][degree] + coefficient * powers[offset][degree], modulus);
            }
        }
    }
    var composed = blocks[block_count - 1];
    var block = block_count - 1;
    while (block > 0) : (block -= 1) {
        composed = multiplyTruncated(composed, powers[block_size], n);
        for (0..n) |degree|
            composed[degree] = @mod(composed[degree] + blocks[block - 1][degree], modulus);
    }
    const output = output_opt.?;
    for (0..n) |degree| storeLe(output, 8 * degree, composed[degree]);
    return @intCast(bytes);
}
