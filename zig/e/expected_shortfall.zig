const MAX_RETURNS: usize = 64;
const MAX_PARSED_RETURNS: i64 = 65;
const SCALE: i64 = 1_000_000;
const MAX_SAMPLE: i64 = 1_000_000_000;
const MAX_INPUT_LENGTH: usize = 67;
const INVALID_RESULT: f64 = -1.0e300;

fn sift_down(values: []f64, root_start: usize, end: usize) void {
    var root = root_start;
    while (root < end / 2) {
        var child = root * 2 + 1;
        if (child + 1 < end and values[child] < values[child + 1]) child += 1;
        if (values[root] >= values[child]) break;
        const temporary = values[root]; values[root] = values[child]; values[child] = temporary;
        root = child;
    }
}

fn heap_sort(values: []f64) void {
    const length = values.len;
    var offset: usize = 0;
    while (offset < length / 2) : (offset += 1) sift_down(values, length / 2 - 1 - offset, length);
    var ending = length;
    while (ending > 1) {
        const temporary = values[0]; values[0] = values[ending - 1]; values[ending - 1] = temporary;
        ending -= 1;
        sift_down(values, 0, ending);
    }
}

export fn expected_shortfall(input: [*c]const i64, length: usize) f64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const confidence_micro = input[0];
    const count_value = input[1];
    if (confidence_micro < 1 or confidence_micro >= SCALE or count_value < 1 or count_value > MAX_PARSED_RETURNS) return INVALID_RESULT;
    if (length != 2 + @as(usize, @intCast(count_value)) or count_value > 64) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    var returns: [MAX_RETURNS]f64 = @splat(0.0);
    for (0..count) |index| {
        const value = input[2 + index];
        if (value < -MAX_SAMPLE or value > MAX_SAMPLE) return INVALID_RESULT;
        returns[index] = @as(f64, @floatFromInt(value)) / @as(f64, @floatFromInt(SCALE));
    }
    heap_sort(returns[0..count]);
    const confidence = @as(f64, @floatFromInt(confidence_micro)) / @as(f64, @floatFromInt(SCALE));
    const quantile = 1.0 - confidence;
    const position = @as(f64, @floatFromInt(count - 1)) * quantile;
    const lower: usize = @intFromFloat(position);
    const fraction = position - @as(f64, @floatFromInt(lower));
    const threshold = if (lower == count - 1) returns[count - 1]
        else returns[lower] * (1.0 - fraction) + returns[lower + 1] * fraction;
    var tail_sum: f64 = 0.0;
    var tail_count: usize = 0;
    for (returns[0..count]) |value| {
        if (value <= threshold) { tail_sum += value; tail_count += 1; }
    }
    return -tail_sum / @as(f64, @floatFromInt(tail_count));
}
