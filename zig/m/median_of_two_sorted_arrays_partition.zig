/// Find twice the median by binary-searching a partition of the shorter array.
const MAX_ARRAY_LENGTH: usize = 1000;

export fn median_of_two_sorted_arrays_partition(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > 2 * MAX_ARRAY_LENGTH + 2) return -2_000_001;
    if (input[0] < 0 or input[0] > MAX_ARRAY_LENGTH or
        input[1] < 0 or input[1] > MAX_ARRAY_LENGTH) return -2_000_001;
    const first_count: usize = @intCast(input[0]);
    const second_count: usize = @intCast(input[1]);
    const total_count = first_count + second_count;
    if (total_count == 0 or total_count > 2 * MAX_ARRAY_LENGTH or length != total_count + 2) return -2_000_001;

    const first_start: usize = 2;
    const second_start = first_start + first_count;
    for (0..first_count) |index| {
        const value = input[first_start + index];
        if (value < -1_000_000 or value > 1_000_000 or
            (index > 0 and input[first_start + index - 1] > value)) return -2_000_001;
    }
    for (0..second_count) |index| {
        const value = input[second_start + index];
        if (value < -1_000_000 or value > 1_000_000 or
            (index > 0 and input[second_start + index - 1] > value)) return -2_000_001;
    }

    var short_start = first_start;
    var long_start = second_start;
    var short_count = first_count;
    var long_count = second_count;
    if (short_count > long_count) {
        const temporary_start = short_start;
        short_start = long_start;
        long_start = temporary_start;
        const temporary_count = short_count;
        short_count = long_count;
        long_count = temporary_count;
    }
    var low: usize = 0;
    var high = short_count;
    const left_count = (total_count + 1) / 2;
    while (low <= high) {
        const first_cut = low + (high - low) / 2;
        const second_cut = left_count - first_cut;
        const first_left: i64 = if (first_cut == 0) -2_000_001 else input[short_start + first_cut - 1];
        const first_right: i64 = if (first_cut == short_count) 2_000_001 else input[short_start + first_cut];
        const second_left: i64 = if (second_cut == 0) -2_000_001 else input[long_start + second_cut - 1];
        const second_right: i64 = if (second_cut == long_count) 2_000_001 else input[long_start + second_cut];

        if (first_left <= second_right and second_left <= first_right) {
            const left_max = @max(first_left, second_left);
            if (total_count % 2 != 0) return left_max * 2;
            return left_max + @min(first_right, second_right);
        }
        if (first_left > second_right) {
            if (first_cut == 0) return -2_000_001;
            high = first_cut - 1;
        } else {
            low = first_cut + 1;
        }
    }
    return -2_000_001;
}
