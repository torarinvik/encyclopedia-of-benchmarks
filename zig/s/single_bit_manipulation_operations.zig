export fn single_bit_manipulation_operations(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 3) return -1;
    const values = input.?;
    const opcode, number, position = .{ values[0], values[1], values[2] };
    if (opcode < 0 or opcode > 5 or number < -2147483648 or number > 2147483647) return -1;
    if (opcode == 5) {
        if (position != -1) return -1;
        return number & (number - 1);
    }
    if (position < 0 or position > 31) return -1;
    const mask: i64 = @as(i64, 1) << @intCast(position);
    return switch (opcode) {
        0 => number | mask,
        1 => number & ~mask,
        2 => number ^ mask,
        3 => @intCast((@as(u64, @bitCast(number)) >> @intCast(position)) & 1),
        4 => if ((number & mask) != 0) 1 else 0,
        else => -1,
    };
}
