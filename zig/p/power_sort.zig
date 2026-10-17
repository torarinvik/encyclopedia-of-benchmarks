const MAX_VALUES: usize = 64;
const MAX_INPUT_VALUES: usize = 67;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;

const Run = struct { start: usize, length: usize, power: i64 };

fn keyLess(left: i64, right: i64, reverse: bool) bool {
    return if (reverse) left > right else left < right;
}

fn findRun(values: []i64, start: usize, end: usize, reverse: bool) usize {
    if (start >= end - 1) return start + 1;
    var run_end = start + 1;
    if (keyLess(values[run_end], values[start], reverse)) {
        while (run_end < end and keyLess(values[run_end], values[run_end - 1], reverse)) : (run_end += 1) {}
        std.mem.reverse(i64, values[start..run_end]);
    } else {
        while (run_end < end and !keyLess(values[run_end], values[run_end - 1], reverse)) : (run_end += 1) {}
    }
    return run_end;
}

fn nodePower(total_length: usize, b1: usize, n1: usize, b2: usize, n2: usize) i64 {
    const a: i64 = @intCast(2 * b1 + n1);
    const b: i64 = @intCast(2 * b2 + n2);
    const denominator: i64 = @intCast(2 * total_length);
    var power: u6 = 0;
    while (@divTrunc(a * (@as(i64, 1) << power), denominator) ==
           @divTrunc(b * (@as(i64, 1) << power), denominator)) : (power += 1) {}
    return power;
}

fn mergeRuns(values: []i64, start1: usize, end1: usize, end2: usize, reverse: bool) void {
    var left: [MAX_VALUES]i64 = @splat(0);
    var right: [MAX_VALUES]i64 = @splat(0);
    const left_length = end1 - start1;
    const right_length = end2 - end1;
    @memcpy(left[0..left_length], values[start1..end1]);
    @memcpy(right[0..right_length], values[end1..end2]);
    var i: usize = 0;
    var j: usize = 0;
    var output = start1;
    while (i < left_length and j < right_length) {
        const take_left = if (reverse) left[i] >= right[j] else left[i] <= right[j];
        if (take_left) { values[output] = left[i]; i += 1; } else { values[output] = right[j]; j += 1; }
        output += 1;
    }
    while (i < left_length) : (i += 1) { values[output] = left[i]; output += 1; }
    while (j < right_length) : (j += 1) { values[output] = right[j]; output += 1; }
}

fn powerSort(values: []i64, reverse: bool) void {
    const length = values.len;
    if (length <= 1) return;
    var stack: [MAX_VALUES]Run = @splat(.{ .start = 0, .length = 0, .power = 0 });
    var stack_size: usize = 0;
    var start: usize = 0;
    while (start < length) {
        const run_end = findRun(values, start, length, reverse);
        var run_length = run_end - start;
        var power: i64 = 0;
        if (stack_size > 0) power = nodePower(length, stack[stack_size - 1].start,
            stack[stack_size - 1].length, start, run_length);
        while (stack_size > 0 and stack[stack_size - 1].power >= power) {
            stack_size -= 1;
            const previous = stack[stack_size];
            mergeRuns(values, previous.start, previous.start + previous.length, run_end, reverse);
            start = previous.start;
            run_length = run_end - start;
            power = 0;
            if (stack_size > 0) power = nodePower(length, stack[stack_size - 1].start,
                stack[stack_size - 1].length, start, run_length);
        }
        stack[stack_size] = .{ .start = start, .length = run_length, .power = power };
        stack_size += 1;
        start = run_end;
    }
    while (stack_size > 1) {
        stack_size -= 1;
        const right = stack[stack_size];
        stack_size -= 1;
        const left = stack[stack_size];
        const merged_end = right.start + right.length;
        mergeRuns(values, left.start, left.start + left.length, merged_end, reverse);
        const merged_length = merged_end - left.start;
        var power: i64 = 0;
        if (stack_size > 0) power = nodePower(length, stack[stack_size - 1].start,
            stack[stack_size - 1].length, left.start, merged_length);
        stack[stack_size] = .{ .start = left.start, .length = merged_length, .power = power };
        stack_size += 1;
    }
}

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn power_sort(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const values_in = input.?[0..length];
    const reverse_value = values_in[0];
    const count_value = values_in[1];
    if ((reverse_value != 0 and reverse_value != 1) or count_value < 0 or count_value > MAX_VALUES) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + count) return -1;
    var values: [MAX_VALUES]i64 = @splat(0);
    for (0..count) |index| {
        const value = values_in[2 + index];
        if (value < MIN_VALUE or value > MAX_VALUE) return -1;
        values[index] = value;
    }
    if (count == 0) return 0;
    const output_bytes = 8 * count;
    if (output == null or capacity < output_bytes) return -2;
    powerSort(values[0..count], reverse_value == 1);
    for (0..count) |index| writeI64Le(output.?, 8 * index, values[index]);
    return @intCast(output_bytes);
}
