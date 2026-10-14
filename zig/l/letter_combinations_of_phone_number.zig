/// Recursively enumerate 2–9 keypad letters into fixed-width concatenated slots.
fn letterCount(digit: i64) usize {
    return if (digit == 7 or digit == 9) 4 else 3;
}

fn letterBase(digit: i64) u8 {
    return switch (digit) {
        2 => 'a', 3 => 'd', 4 => 'g', 5 => 'j',
        6 => 'm', 7 => 'p', 8 => 't', else => 'w',
    };
}

fn expand(digits: [*]const i64, length: usize, index: usize, output: [*]u8,
          output_offset: usize, combination_count: usize) void {
    if (index == length) return;
    const alternatives = letterCount(digits[index]);
    const block_count = combination_count / alternatives;
    const base = letterBase(digits[index]);
    for (0..alternatives) |letter| {
        const branch_offset = output_offset + letter * block_count * length;
        for (0..block_count) |row| {
            output[branch_offset + row * length + index] = base + @as(u8, @intCast(letter));
        }
        expand(digits, length, index + 1, output, branch_offset, block_count);
    }
}

// Output is lexicographic and uses one fixed-width byte string per combination.
export fn letter_combinations_of_phone_number(digits: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length == 0) return 0;
    var count: usize = 1;
    if (length > 6) return -1;
    for (0..length) |index| {
        const digit = digits[index];
        if (digit < 2 or digit > 9) return -1;
        count *= letterCount(digit);
    }
    const required = count * length;
    if (output_capacity < required) return -2;
    expand(digits, length, 0, output, 0, count);
    return @intCast(count);
}
