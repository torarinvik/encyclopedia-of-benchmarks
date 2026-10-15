/// Find the rightmost longest ASCII alphanumeric palindrome with substring DP.
const std = @import("std");
const MAX_INPUT_LENGTH: usize = 1000;

fn isAsciiAlphanumeric(value: i64) bool {
    return (value >= 48 and value <= 57) or
        (value >= 65 and value <= 90) or
        (value >= 97 and value <= 122);
}

export fn longest_palindromic_substring_dp(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length == 0 or length > MAX_INPUT_LENGTH) return -1;
    for (0..length) |index| {
        if (!isAsciiAlphanumeric(values[index])) return -1;
    }

    const palindrome = std.heap.page_allocator.alloc(bool, length * length) catch return -1;
    defer std.heap.page_allocator.free(palindrome);
    var best_start: usize = 0;
    var best_length: usize = 0;
    for (0..length) |end| {
        for (0..end + 1) |start| {
            const is_palindrome = values[start] == values[end] and
                (end - start < 2 or palindrome[(start + 1) * length + end - 1]);
            palindrome[start * length + end] = is_palindrome;
            const candidate_length = end - start + 1;
            if (is_palindrome and (candidate_length > best_length or
                (candidate_length == best_length and start > best_start))) {
                best_start = start;
                best_length = candidate_length;
            }
        }
    }

    if (output == null or output_capacity < best_length) return -2;
    for (0..best_length) |index| {
        output[index] = @intCast(values[best_start + index]);
    }
    return @intCast(best_length);
}
