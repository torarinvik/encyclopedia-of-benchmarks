const MAX_ARRAY_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_ARRAY_LENGTH;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_INPUT_LENGTH + 1;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;
const CHECKSUM_OFFSET: i64 = 1_000_001;

export fn merge_sorted(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (values[0] < 0 or values[0] > @as(i64, @intCast(MAX_ARRAY_LENGTH)) or
        values[1] < 0 or values[1] > @as(i64, @intCast(MAX_ARRAY_LENGTH))) return -1;

    const left_count: usize = @intCast(values[0]);
    const right_count: usize = @intCast(values[1]);
    if (length != 2 + left_count + right_count) return -1;
    const right_start = 2 + left_count;

    for (0..left_count) |index| {
        const value = values[2 + index];
        if (value < MIN_VALUE or value > MAX_VALUE or
            (index > 0 and values[2 + index - 1] > value)) return -1;
    }
    for (0..right_count) |index| {
        const value = values[right_start + index];
        if (value < MIN_VALUE or value > MAX_VALUE or
            (index > 0 and values[right_start + index - 1] > value)) return -1;
    }

    var left_index: usize = 0;
    var right_index: usize = 0;
    var output_index: i64 = 0;
    var checksum: i64 = 0;
    while (left_index < left_count and right_index < right_count) {
        const value: i64 = if (values[2 + left_index] <= values[right_start + right_index]) blk: {
            const selected = values[2 + left_index];
            left_index += 1;
            break :blk selected;
        } else blk: {
            const selected = values[right_start + right_index];
            right_index += 1;
            break :blk selected;
        };
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET);
        output_index += 1;
    }
    while (left_index < left_count) {
        const value = values[2 + left_index];
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET);
        left_index += 1;
        output_index += 1;
    }
    while (right_index < right_count) {
        const value = values[right_start + right_index];
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET);
        right_index += 1;
        output_index += 1;
    }
    return checksum;
}
