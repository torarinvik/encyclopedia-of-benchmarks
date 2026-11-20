const MAX_N: usize = 64;
const MAX_INPUT: usize = 67;
const MAX_SEGMENTS: usize = 65;

fn gcdNonnegative(a_value: i64, b_value: i64) i64 {
    var a = a_value;
    var b = b_value;
    while (b != 0) {
        const remainder = @mod(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn combineValue(mode: i64, a: i64, b: i64) i64 {
    if (mode == 0) return gcdNonnegative(a, b);
    if (mode == 1) return a | b;
    return a & b;
}

export fn distinct_subarray_aggregates(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?[0..length];
    const mode = input[0];
    const n_value = input[1];
    if (mode < 0 or mode > 2 or n_value < 0 or n_value > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(n_value);
    if (length != 2 + n) return -1;

    var segment_value: [MAX_SEGMENTS]i64 = @splat(0);
    var segment_left: [MAX_SEGMENTS]i64 = @splat(0);
    var segment_right: [MAX_SEGMENTS]i64 = @splat(0);
    var segment_count: usize = 0;
    var aggregate_sum: i64 = 0;
    var suffix_distinct_count: i64 = 0;
    for (0..n) |right| {
        const value = input[2 + right];
        if (value < 0 or value > 255) return -1;
        for (0..segment_count) |j| {
            segment_value[j] = combineValue(mode, segment_value[j], value);
        }
        segment_value[segment_count] = value;
        segment_left[segment_count] = @intCast(right);
        segment_right[segment_count] = @intCast(right);
        segment_count += 1;

        var write: usize = 0;
        for (0..segment_count) |read| {
            if (write > 0 and segment_value[read] == segment_value[write - 1]) {
                segment_right[write - 1] = segment_right[read];
            } else {
                segment_value[write] = segment_value[read];
                segment_left[write] = segment_left[read];
                segment_right[write] = segment_right[read];
                write += 1;
            }
        }
        segment_count = write;
        suffix_distinct_count += @intCast(segment_count);
        for (0..segment_count) |j| {
            aggregate_sum += segment_value[j] * (segment_right[j] - segment_left[j] + 1);
        }
    }
    return aggregate_sum * 1024 + suffix_distinct_count;
}
