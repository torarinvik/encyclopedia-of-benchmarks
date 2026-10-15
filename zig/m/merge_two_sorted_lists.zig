/// Linear merge over two packed ascending i32 sequences.
const MAX_TOTAL_LENGTH: usize = 1024;

export fn merge_two_sorted_lists(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_TOTAL_LENGTH + 2) return -1;
    const first_value = input[0];
    const second_value = input[1];
    if (first_value < 0 or first_value > MAX_TOTAL_LENGTH or
        second_value < 0 or second_value > MAX_TOTAL_LENGTH) return -1;
    const first_count: usize = @intCast(first_value);
    const second_count: usize = @intCast(second_value);
    if (first_count + second_count > MAX_TOTAL_LENGTH or
        length != first_count + second_count + 2) return -1;
    for (0..first_count) |index| {
        const value = input[index + 2];
        if (value < -2147483648 or value > 2147483647 or
            (index > 0 and input[index + 1] > value)) return -1;
    }
    const second_start = first_count + 2;
    for (0..second_count) |index| {
        const value = input[second_start + index];
        if (value < -2147483648 or value > 2147483647 or
            (index > 0 and input[second_start + index - 1] > value)) return -1;
    }

    const total_count = first_count + second_count;
    const output_bytes = total_count * 4;
    if (output_capacity < output_bytes or (output_bytes != 0 and output == null)) return -2;
    var first_index: usize = 0;
    var second_index: usize = 0;
    for (0..total_count) |written| {
        var value: i64 = 0;
        if (first_index == first_count) {
            value = input[second_start + second_index];
            second_index += 1;
        } else if (second_index == second_count) {
            value = input[first_index + 2];
            first_index += 1;
        } else if (input[first_index + 2] <= input[second_start + second_index]) {
            value = input[first_index + 2];
            first_index += 1;
        } else {
            value = input[second_start + second_index];
            second_index += 1;
        }
        const signed_value: i32 = @intCast(value);
        const bits: u32 = @bitCast(signed_value);
        for (0..4) |byte| {
            output[written * 4 + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
        }
    }
    return @intCast(total_count);
}
