/// Emit the sorted unique pairwise sums of two bounded integer sets.
const min_sum: i64 = -2000;
const sum_count: usize = 4001;
const max_set_size: i64 = 64;

fn decimalWidth(value_input: i64) usize {
    var value = value_input;
    var width: usize = 1;
    if (value < 0) { value = -value; width += 1; }
    while (value >= 10) { value = @divTrunc(value, 10); width += 1; }
    return width;
}

fn appendSignedDecimal(output: [*]u8, position_input: usize, value_input: i64) usize {
    var value = value_input;
    var position = position_input;
    if (value < 0) { output[position] = '-'; position += 1; value = -value; }
    var digits: [20]u8 = undefined;
    var count: usize = 0;
    while (true) {
        digits[count] = @intCast(@mod(value, 10));
        count += 1;
        value = @divTrunc(value, 10);
        if (value == 0) break;
    }
    while (count > 0) {
        count -= 1;
        output[position] = '0' + digits[count];
        position += 1;
    }
    return position;
}

export fn sumset(values: [*c]const i64, length: usize,
                 output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2) return -1;
    const count_a = values[0];
    const count_b = values[1];
    if (count_a < 0 or count_a > max_set_size or count_b < 0 or count_b > max_set_size or
        length != 2 + @as(usize, @intCast(count_a)) + @as(usize, @intCast(count_b))) return -1;
    var present = [_]bool{false} ** sum_count;
    for (0..@as(usize, @intCast(count_a))) |index_a| {
        const left = values[index_a + 2];
        if (left < -1000 or left > 1000) return -1;
    }
    for (0..@as(usize, @intCast(count_b))) |index_b| {
        const right = values[@as(usize, @intCast(count_a)) + index_b + 2];
        if (right < -1000 or right > 1000) return -1;
    }
    for (0..@as(usize, @intCast(count_a))) |index_a| {
        const left = values[index_a + 2];
        for (0..@as(usize, @intCast(count_b))) |index_b| {
            const right = values[@as(usize, @intCast(count_a)) + index_b + 2];
            present[@intCast(left + right - min_sum)] = true;
        }
    }
    var needed: usize = 0;
    for (present, 0..) |exists, index| {
        if (exists) needed += decimalWidth(@as(i64, @intCast(index)) + min_sum) + 1;
    }
    if (needed == 0) return 0;
    if (output == null or output_capacity < needed) return -2;
    const out = output[0..output_capacity];
    var position: usize = 0;
    for (present, 0..) |exists, index| {
        if (!exists) continue;
        position = appendSignedDecimal(out.ptr, position, @as(i64, @intCast(index)) + min_sum);
        out[position] = '\n'; position += 1;
    }
    return @intCast(position);
}
