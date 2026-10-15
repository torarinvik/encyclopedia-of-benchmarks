const MAX_LENGTH: usize = 100_000;
const MAX_SAFE_INTEGER: i64 = 9_007_199_254_740_991;

pub export fn is_sorted_array(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        const value = values[index];
        if (value < -MAX_SAFE_INTEGER or value > MAX_SAFE_INTEGER) return -1;
    }
    if (length > 1) {
        for (0..length - 1) |index| {
            if (values[index] >= values[index + 1]) return 0;
        }
    }
    return 1;
}
