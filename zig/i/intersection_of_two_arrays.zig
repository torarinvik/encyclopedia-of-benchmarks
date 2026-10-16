const MAX_ARRAY_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 * (MAX_ARRAY_LENGTH + 1);
const BYTES_PER_VALUE: usize = 4;

fn storeI32Le(output: [*c]u8, position: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..BYTES_PER_VALUE) |byte|
        output[position + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn intersection_of_two_arrays(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const packed = input[0..length];
    const first_length_value = packed[0];
    if (first_length_value < 0 or first_length_value > MAX_ARRAY_LENGTH) return -1;
    const first_length: usize = @intCast(first_length_value);
    const second_length_position = 1 + first_length;
    if (second_length_position >= length) return -1;
    const second_length_value = packed[second_length_position];
    if (second_length_value < 0 or second_length_value > MAX_ARRAY_LENGTH) return -1;
    const second_length: usize = @intCast(second_length_value);
    const second_start = second_length_position + 1;
    if (second_start + second_length != length) return -1;

    const first = packed[1..second_length_position];
    const second = packed[second_start..];
    for (first) |value| if (value < -2147483648 or value > 2147483647) return -1;
    for (second) |value| if (value < -2147483648 or value > 2147483647) return -1;
    for (1..first_length) |index| if (first[index - 1] > first[index]) return -1;
    for (1..second_length) |index| if (second[index - 1] > second[index]) return -1;

    const maximum_result = @min(first_length, second_length);
    if (output_capacity < maximum_result * BYTES_PER_VALUE or (maximum_result > 0 and output == null)) return -2;
    var first_index: usize = 0;
    var second_index: usize = 0;
    var result_count: usize = 0;
    var previous_value: i64 = 0;
    while (first_index < first_length and second_index < second_length) {
        const left = first[first_index];
        const right = second[second_index];
        if (left < right) {
            first_index += 1;
        } else if (left > right) {
            second_index += 1;
        } else {
            if (result_count == 0 or left != previous_value) {
                storeI32Le(output, result_count * BYTES_PER_VALUE, left);
                previous_value = left;
                result_count += 1;
            }
            first_index += 1;
            second_index += 1;
        }
    }
    return @intCast(result_count);
}
