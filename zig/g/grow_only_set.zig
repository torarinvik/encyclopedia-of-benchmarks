export fn grow_only_set(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 25) return -1;
    const values = input;
    const count_value = values[0];
    if (count_value < 0 or count_value > 12 or length != 1 + 2 * @as(usize, @intCast(count_value))) return -1;
    var left: u64 = 0;
    var right: u64 = 0;
    var answers: u64 = 0;
    var query_count: usize = 0;
    for (0..@intCast(count_value)) |index| {
        const opcode = values[1 + 2 * index];
        const argument = values[2 + 2 * index];
        if (opcode < 0 or opcode > 7) return -1;
        if (opcode <= 3) {
            if (argument < 0 or argument > 15) return -1;
        } else if (argument != 0) return -1;
        const bit: u64 = if (opcode <= 3) (@as(u64, 1) << @intCast(argument)) else 0;
        switch (opcode) {
            0 => left |= bit,
            1 => right |= bit,
            2 => {
                if (left & bit != 0) answers |= @as(u64, 1) << @intCast(query_count);
                query_count += 1;
            },
            3 => {
                if (right & bit != 0) answers |= @as(u64, 1) << @intCast(query_count);
                query_count += 1;
            },
            4 => {
                if (left & right == left) answers |= @as(u64, 1) << @intCast(query_count);
                query_count += 1;
            },
            5 => {
                if (left & right == right) answers |= @as(u64, 1) << @intCast(query_count);
                query_count += 1;
            },
            6 => left |= right,
            else => right |= left,
        }
    }
    return @intCast(answers | (left << 12) | (right << 28) | (@as(u64, @intCast(query_count)) << 44));
}
