/// Find the leftmost longest ASCII alphanumeric palindrome by expanding centers.
fn isAsciiAlphanumeric(value: i64) bool {
    return (value >= '0' and value <= '9') or
        (value >= 'A' and value <= 'Z') or
        (value >= 'a' and value <= 'z');
}

export fn longest_palindromic_substring(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 1000) return -1;
    for (0..length) |index| {
        if (!isAsciiAlphanumeric(values[index])) return -1;
    }

    var best_start: usize = 0;
    var best_length: usize = 1;
    for (0..length) |center| {
        var left = center;
        var right = center;
        while (left > 0 and right + 1 < length and
            values[left - 1] == values[right + 1]) {
            left -= 1;
            right += 1;
        }
        var candidate_length = right - left + 1;
        if (candidate_length > best_length) {
            best_start = left;
            best_length = candidate_length;
        }

        left = center;
        right = center + 1;
        while (right < length and values[left] == values[right]) {
            candidate_length = right - left + 1;
            if (candidate_length > best_length) {
                best_start = left;
                best_length = candidate_length;
            }
            if (left == 0 or right + 1 == length) break;
            left -= 1;
            right += 1;
        }
    }

    if (output_capacity < best_length) return -2;
    for (0..best_length) |index| {
        output[index] = @intCast(values[best_start + index]);
    }
    return @intCast(best_length);
}
