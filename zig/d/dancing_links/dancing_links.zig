/// Count exact covers and emit selected-row bitmasks in ascending order.
export fn dancing_links(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const universe_value = input[0];
    const row_count_value = input[1];
    if (universe_value < 1 or universe_value > 8 or row_count_value < 0 or row_count_value > 8) return -1;
    const universe: usize = @intCast(universe_value);
    const row_count: usize = @intCast(row_count_value);
    if (length != row_count + 2) return -1;
    const full_mask: i64 = (@as(i64, 1) << @intCast(universe)) - 1;
    for (0..row_count) |row| {
        const mask = input[row + 2];
        if (mask <= 0 or (mask & ~full_mask) != 0) return -1;
    }
    const selection_limit: usize = @as(usize, 1) << @intCast(row_count);
    var solution_count: usize = 0;
    for (0..selection_limit) |selection| {
        var covered: i64 = 0;
        var valid = true;
        for (0..row_count) |row| {
            if ((selection & (@as(usize, 1) << @intCast(row))) == 0) continue;
            const mask = input[row + 2];
            if ((covered & mask) != 0) { valid = false; break; }
            covered |= mask;
        }
        if (valid and covered == full_mask) solution_count += 1;
    }
    if (output_capacity < solution_count or (solution_count != 0 and output == null)) return -2;
    var position: usize = 0;
    for (0..selection_limit) |selection| {
        var covered: i64 = 0;
        var valid = true;
        for (0..row_count) |row| {
            if ((selection & (@as(usize, 1) << @intCast(row))) == 0) continue;
            const mask = input[row + 2];
            if ((covered & mask) != 0) { valid = false; break; }
            covered |= mask;
        }
        if (valid and covered == full_mask) {
            output[position] = @intCast(selection);
            position += 1;
        }
    }
    return @intCast(solution_count);
}
