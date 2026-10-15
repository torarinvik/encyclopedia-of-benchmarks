/// Merge two ascending i32 arrays and return twice their exact median.
const MAX_TOTAL_LENGTH: usize = 1024;

export fn median_of_two_sorted_arrays(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_TOTAL_LENGTH + 2) return -1;
    if (input[0] < 0 or input[0] > MAX_TOTAL_LENGTH or
        input[1] < 0 or input[1] > MAX_TOTAL_LENGTH) return -1;
    const first_count: usize = @intCast(input[0]);
    const second_count: usize = @intCast(input[1]);
    const total_count = first_count + second_count;
    if (total_count == 0 or total_count > MAX_TOTAL_LENGTH or length != total_count + 2) return -1;
    const second_start = first_count + 2;
    for (0..first_count) |index| {
        const value = input[index + 2];
        if (value < -2147483648 or value > 2147483647 or
            (index != 0 and input[index + 1] > value)) return -1;
    }
    for (0..second_count) |index| {
        const value = input[second_start + index];
        if (value < -2147483648 or value > 2147483647 or
            (index != 0 and input[second_start + index - 1] > value)) return -1;
    }

    var merged: [MAX_TOTAL_LENGTH]i32 = undefined;
    var first_index: usize = 0;
    var second_index: usize = 0;
    var written: usize = 0;
    while (first_index < first_count and second_index < second_count) {
        if (input[first_index + 2] <= input[second_start + second_index]) {
            merged[written] = @intCast(input[first_index + 2]);
            first_index += 1;
        } else {
            merged[written] = @intCast(input[second_start + second_index]);
            second_index += 1;
        }
        written += 1;
    }
    while (first_index < first_count) {
        merged[written] = @intCast(input[first_index + 2]);
        first_index += 1;
        written += 1;
    }
    while (second_index < second_count) {
        merged[written] = @intCast(input[second_start + second_index]);
        second_index += 1;
        written += 1;
    }
    if (total_count % 2 != 0) return @as(i64, merged[total_count / 2]) * 2;
    return @as(i64, merged[total_count / 2 - 1]) + merged[total_count / 2];
}
