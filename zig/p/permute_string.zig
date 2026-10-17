const std = @import("std");

const MAX_N: usize = 7;
const MAX_INPUT_LENGTH: usize = 9;

fn factorial(value: usize) usize {
    var result: usize = 1;
    var factor: usize = 2;
    while (factor <= value) : (factor += 1) result *= factor;
    return result;
}

fn uniquePermutationCount(values: []const u8) usize {
    if (values.len == 0) return 0;
    var frequencies: [128]usize = [_]usize{0} ** 128;
    for (values) |value| frequencies[value] += 1;
    var count = factorial(values.len);
    for (frequencies) |frequency| count /= factorial(frequency);
    return count;
}

fn nextPermutation(values: []u8) bool {
    if (values.len < 2) return false;
    var pivot = values.len - 1;
    while (pivot > 0 and values[pivot - 1] >= values[pivot]) pivot -= 1;
    if (pivot == 0) return false;
    var successor = values.len - 1;
    while (values[successor] <= values[pivot - 1]) successor -= 1;
    std.mem.swap(u8, &values[pivot - 1], &values[successor]);
    std.mem.reverse(u8, values[pivot..]);
    return true;
}

export fn permute_string(input: [*c]const i64, input_length: usize,
                         output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_INPUT_LENGTH) return -1;
    const values = input;
    if (values[0] < 0 or values[0] > MAX_N) return -1;
    const character_count: usize = @intCast(values[0]);
    if (input_length != character_count + 1) return -1;

    var characters: [MAX_N]u8 = [_]u8{0} ** MAX_N;
    for (0..character_count) |index| {
        const value = values[index + 1];
        if (value < 0 or value > 127) return -1;
        characters[index] = @intCast(value);
    }
    std.mem.sort(u8, characters[0..character_count], {}, comptime std.sort.asc(u8));
    const permutation_count = uniquePermutationCount(characters[0..character_count]);
    const output_bytes = permutation_count * character_count;
    if (output == null or output_capacity < output_bytes) return -2;
    const result = output;
    for (0..permutation_count) |row| {
        for (0..character_count) |column| result[row * character_count + column] = characters[column];
        if (row + 1 < permutation_count) _ = nextPermutation(characters[0..character_count]);
    }
    return @intCast(output_bytes);
}
