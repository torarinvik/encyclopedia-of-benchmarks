/* Modified bounded-profile derivative; carry benchmarks/b/bmm/LICENSE with this source. */

const MAX_SIZE: usize = 128;
const SOURCE_SIZE: usize = 1024;
const MAX_CELLS: usize = MAX_SIZE * MAX_SIZE;
const MAX_OUTPUT_BYTES: usize = 29;

fn nextRandom(state: *u32) u32 {
    state.* = state.* *% 1_664_525 +% 1_013_904_223;
    return (state.* >> 16) & 0x7fff;
}

fn appendUnsigned(value_input: u32, staged: *[MAX_OUTPUT_BYTES]u8, used: *usize) void {
    var value = value_input;
    var reverse: [10]u8 = undefined;
    var count: usize = 0;
    while (true) {
        reverse[count] = '0' + @as(u8, @intCast(value % 10));
        count += 1;
        value /= 10;
        if (value == 0) break;
    }
    while (count > 0) {
        count -= 1;
        staged[used.*] = reverse[count];
        used.* += 1;
    }
}

export fn versabench_bmm(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    const size_value = input[0];
    const block_value = input[1];
    if (size_value < 1 or size_value > @as(i64, @intCast(MAX_SIZE)) or block_value < 1 or
        block_value > size_value or @rem(size_value, block_value) != 0) return -1;
    const size: usize = @intCast(size_value);
    const block: usize = @intCast(block_value);

    var a = [_]f32{0} ** MAX_CELLS;
    var b = [_]f32{0} ** MAX_CELLS;
    var c = [_]f32{0} ** MAX_CELLS;
    var seed: u32 = 1;
    for (0..size) |i| {
        for (0..SOURCE_SIZE) |j| {
            const random_a = nextRandom(&seed);
            const random_b = nextRandom(&seed);
            if (j < size) {
                const shift_a = ((j & 31) + 32 - (i & 31)) & 31;
                const shift_b = (i + j) & 31;
                a[i * size + j] = @floatFromInt((random_a >> @intCast(shift_a)) & 15);
                b[i * size + j] = @floatFromInt((random_b << @intCast(shift_b)) & 15);
            }
        }
    }

    var outer_i: usize = 0;
    while (outer_i < size) : (outer_i += block) {
        var outer_j: usize = 0;
        while (outer_j < size) : (outer_j += block) {
            var outer_k: usize = 0;
            while (outer_k < size) : (outer_k += block) {
                for (outer_i..outer_i + block) |i| {
                    for (outer_j..outer_j + block) |j| {
                        const cell = i * size + j;
                        for (outer_k..outer_k + block) |k| c[cell] += a[i * size + k] * b[k * size + j];
                    }
                }
            }
        }
    }

    var total: f32 = 0;
    outer_i = 0;
    while (outer_i < size) : (outer_i += block) {
        var outer_j: usize = 0;
        while (outer_j < size) : (outer_j += block) {
            var subtotal: f32 = 0;
            for (outer_i..outer_i + block) |i| {
                for (outer_j..outer_j + block) |j| subtotal += c[i * size + j];
            }
            total += subtotal;
        }
    }

    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    var used: usize = 0;
    @memcpy(staged[0..12], "final sum = ");
    used = 12;
    appendUnsigned(@intFromFloat(total), &staged, &used);
    @memcpy(staged[used .. used + 8], ".000000\n");
    used += 8;
    if (output == null or output_capacity < used) return -2;
    @memcpy(output[0..used], staged[0..used]);
    return @intCast(used);
}
