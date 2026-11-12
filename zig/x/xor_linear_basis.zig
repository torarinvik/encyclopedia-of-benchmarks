const MAX_OPERATIONS: usize = 64;
const MAX_INSERTIONS: usize = 16;
const MAX_INPUT_VALUES: usize = 1 + 2 * MAX_OPERATIONS;
const BIT_COUNT: usize = 63;

fn insertValue(basis: *[BIT_COUNT]u64, value: u64) void {
    var reduced = value;
    var bit: usize = BIT_COUNT;
    while (bit > 0) {
        bit -= 1;
        if (reduced == 0) break;
        const mask = @as(u64, 1) << @intCast(bit);
        if ((reduced & mask) == 0) continue;
        if (basis[bit] == 0) {
            basis[bit] = reduced;
            return;
        }
        reduced ^= basis[bit];
    }
}

fn maximumValue(basis: *const [BIT_COUNT]u64) u64 {
    var best: u64 = 0;
    var bit: usize = BIT_COUNT;
    while (bit > 0) {
        bit -= 1;
        const candidate = best ^ basis[bit];
        if (candidate > best) best = candidate;
    }
    return best;
}

fn containsValue(basis: *const [BIT_COUNT]u64, raw_value: u64) bool {
    var value = raw_value;
    var bit: usize = BIT_COUNT;
    while (bit > 0) {
        bit -= 1;
        const mask = @as(u64, 1) << @intCast(bit);
        if ((value & mask) == 0) continue;
        if (basis[bit] == 0) return false;
        value ^= basis[bit];
    }
    return value == 0;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn xor_linear_basis(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const input = input_opt.?;
    const q_value = input[0];
    if (q_value < 1 or q_value > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
    const q: usize = @intCast(q_value);

    var basis: [BIT_COUNT]u64 = @splat(0);
    var results: [MAX_OPERATIONS]i64 = @splat(0);
    var result_count: usize = 0;
    var cursor: usize = 1;
    var insertion_count: usize = 0;
    for (0..q) |_| {
        if (cursor >= length) return -1;
        const kind = input[cursor];
        cursor += 1;
        if (kind == 0 or kind == 2) {
            if (cursor >= length) return -1;
            const raw_value = input[cursor];
            cursor += 1;
            if (raw_value < 0) return -1;
            const value: u64 = @intCast(raw_value);
            if (kind == 0) {
                insertion_count += 1;
                if (insertion_count > MAX_INSERTIONS) return -1;
                insertValue(&basis, value);
            } else {
                results[result_count] = if (containsValue(&basis, value)) 1 else 0;
                result_count += 1;
            }
        } else if (kind == 1) {
            results[result_count] = @intCast(maximumValue(&basis));
            result_count += 1;
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;
    const output_bytes = result_count * 8;
    if (output_bytes == 0) return 0;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..result_count) |result| storeLe(output, result * 8, results[result]);
    return @intCast(output_bytes);
}
