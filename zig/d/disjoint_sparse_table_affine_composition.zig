const MOD: i64 = 1_000_000_007;
const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_LEVELS: usize = 5;

const Affine = struct { a: i64, b: i64 };

fn combine(left: Affine, right: Affine) Affine {
    return .{
        .a = @mod(right.a * left.a, MOD),
        .b = @mod(right.a * left.b + right.b, MOD),
    };
}

fn putWord(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn disjoint_sparse_table_affine_composition(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > 130) return -1;
    const values = input[0..length];
    const n_value = values[0];
    const q_value = values[1];
    if (n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + 2 * n + 2 * q) return -1;

    var maps: [MAX_N]Affine = @splat(.{ .a = 0, .b = 0 });
    var left: [MAX_Q]usize = @splat(0);
    var right: [MAX_Q]usize = @splat(0);
    var cursor: usize = 2;
    for (0..n) |index| {
        const a = values[cursor];
        const b = values[cursor + 1];
        cursor += 2;
        if (a < 0 or a >= MOD or b < 0 or b >= MOD) return -1;
        maps[index] = .{ .a = a, .b = b };
    }
    for (0..q) |query| {
        const lo = values[cursor];
        const hi = values[cursor + 1];
        cursor += 2;
        if (lo < 0 or lo > hi or hi >= n_value) return -1;
        left[query] = @intCast(lo);
        right[query] = @intCast(hi);
    }
    const output_bytes = q * 16;
    if (output == null or capacity < output_bytes) return -2;

    var table: [MAX_LEVELS][MAX_N]Affine = @splat(@splat(.{ .a = 0, .b = 0 }));
    var levels: usize = 0;
    var span: usize = 1;
    while (span < n) : (span <<= 1) levels += 1;
    for (0..levels) |level| {
        const half = @as(usize, 1) << @intCast(level);
        const width = half << 1;
        var start: usize = 0;
        while (start < n) : (start += width) {
            const middle = @min(start + half, n);
            const end = @min(start + width, n);
            if (middle > start) {
                table[level][middle - 1] = maps[middle - 1];
                var index = middle - 1;
                while (index > start) : (index -= 1)
                    table[level][index - 1] = combine(maps[index - 1], table[level][index]);
            }
            if (middle < end) {
                table[level][middle] = maps[middle];
                var index = middle + 1;
                while (index < end) : (index += 1)
                    table[level][index] = combine(table[level][index - 1], maps[index]);
            }
        }
    }
    for (0..q) |query| {
        var answer: Affine = undefined;
        if (left[query] == right[query]) answer = maps[left[query]] else {
            var difference = left[query] ^ right[query];
            var level: usize = 0;
            while (difference > 1) : (level += 1) difference >>= 1;
            answer = combine(table[level][left[query]], table[level][right[query]]);
        }
        putWord(output, query * 16, answer.a);
        putWord(output, query * 16 + 8, answer.b);
    }
    return @intCast(output_bytes);
}
