/// Run-length-native LCS by run-pair blocks and boundary propagation.
export fn rle_lcs_block_dp(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > 18) return -1;
    const input = input_opt.?;
    const left_count_raw = input[0];
    if (left_count_raw < 1 or left_count_raw > 4) return -1;
    const left_count: usize = @intCast(left_count_raw);
    const right_count_index = 1 + 2 * left_count;
    if (right_count_index >= length) return -1;
    const right_count_raw = input[right_count_index];
    if (right_count_raw < 1 or right_count_raw > 4) return -1;
    const right_count: usize = @intCast(right_count_raw);
    if (length != right_count_index + 1 + 2 * right_count) return -1;
    var left_symbol: [4]i64 = [_]i64{0} ** 4;
    var left_size: [4]usize = [_]usize{0} ** 4;
    var right_symbol: [4]i64 = [_]i64{0} ** 4;
    var right_size: [4]usize = [_]usize{0} ** 4;
    var left_total: usize = 0;
    var right_total: usize = 0;
    for (0..left_count) |run| {
        const symbol = input[1 + 2 * run];
        const size = input[2 + 2 * run];
        if (symbol < 0 or symbol > 3 or size < 1 or size > 8) return -1;
        left_total += @intCast(size);
        if (left_total > 16) return -1;
        left_symbol[run] = symbol;
        left_size[run] = @intCast(size);
    }
    for (0..right_count) |run| {
        const symbol = input[right_count_index + 1 + 2 * run];
        const size = input[right_count_index + 2 + 2 * run];
        if (symbol < 0 or symbol > 3 or size < 1 or size > 8) return -1;
        right_total += @intCast(size);
        if (right_total > 16) return -1;
        right_symbol[run] = symbol;
        right_size[run] = @intCast(size);
    }
    var bottom: [4][9]i64 = [_][9]i64{[_]i64{0} ** 9} ** 4;
    var next_bottom: [4][9]i64 = [_][9]i64{[_]i64{0} ** 9} ** 4;
    for (0..left_count) |i| {
        var left_boundary: [9]i64 = [_]i64{0} ** 9;
        for (0..right_count) |j| {
            const rows = left_size[i];
            const columns = right_size[j];
            var previous: [9]i64 = [_]i64{0} ** 9;
            var current: [9]i64 = [_]i64{0} ** 9;
            var right_boundary: [9]i64 = [_]i64{0} ** 9;
            for (0..columns + 1) |column| previous[column] = bottom[j][column];
            right_boundary[0] = previous[columns];
            for (1..rows + 1) |row| {
                current[0] = left_boundary[row];
                for (1..columns + 1) |column| {
                    if (left_symbol[i] == right_symbol[j]) {
                        current[column] = previous[column - 1] + 1;
                    } else {
                        current[column] = @max(previous[column], current[column - 1]);
                    }
                }
                right_boundary[row] = current[columns];
                for (0..columns + 1) |column| previous[column] = current[column];
            }
            for (0..columns + 1) |column| next_bottom[j][column] = previous[column];
            for (0..rows + 1) |row| left_boundary[row] = right_boundary[row];
        }
        for (0..right_count) |j| {
            for (0..right_size[j] + 1) |column| bottom[j][column] = next_bottom[j][column];
        }
    }
    return bottom[right_count - 1][right_size[right_count - 1]];
}
