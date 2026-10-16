const MAX_LENGTH: usize = 1024;
const MAX_ABS_VALUE: i64 = 1_000_000;

export fn maximum_subarray_int32(values: [*c]const i64, length: usize) i64 {
    if (values == null or length == 0 or length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        if (values[index] < -MAX_ABS_VALUE or values[index] > MAX_ABS_VALUE) return -1;
    }
    var current = values[0];
    var best = current;
    for (1..length) |index| {
        current = if (current > 0) current + values[index] else values[index];
        if (current > best) best = current;
    }
    return best;
}
