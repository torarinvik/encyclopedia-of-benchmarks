/// Square a sorted array and emit the results in ascending order.
const MAX_ARRAY_LENGTH: usize = 10000;

export fn squares_of_a_sorted_array(input: [*]const i64, length: usize,
                                    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_ARRAY_LENGTH) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (value < -10000 or value > 10000) return -1;
        if (index != 0 and input[index - 1] > value) return -1;
    }
    const output_bytes = length * 8;
    if (output_capacity < output_bytes) return -2;

    var left: usize = 0;
    var right = length;
    var destination = length;
    while (destination > 0) {
        destination -= 1;
        const left_value = input[left];
        const right_value = input[right - 1];
        const left_magnitude = if (left_value < 0) -left_value else left_value;
        const right_magnitude = if (right_value < 0) -right_value else right_value;
        var value: i64 = undefined;
        if (left_magnitude > right_magnitude) {
            value = left_value;
            left += 1;
        } else {
            value = right_value;
            right -= 1;
        }
        const square: u64 = @intCast(value * value);
        for (0..8) |byte| output[destination * 8 + byte] = @truncate(square >> @intCast(byte * 8));
    }
    return @intCast(length);
}
