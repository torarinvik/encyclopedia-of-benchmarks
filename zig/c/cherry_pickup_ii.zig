const MAX_DIM: usize = 6;
const MAX_INPUT: usize = 39;

export fn cherry_pickup_ii(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 6 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const rows_value = input[0];
    const columns_value = input[1];
    if (rows_value < 2 or rows_value > 6 or columns_value < 2 or columns_value > 6) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    if (length != 2 + rows * columns) return -1;
    for (0..rows * columns) |i| { if (input[2 + i] < 0 or input[2 + i] > 100) return -1; }
    var previous = [_]i64{-1} ** (MAX_DIM * MAX_DIM);
    var current = [_]i64{-1} ** (MAX_DIM * MAX_DIM);
    previous[columns - 1] = input[2] + input[2 + columns - 1];
    for (1..rows) |row| {
        @memset(&current, -1);
        for (0..columns) |left| {
            for (0..columns) |right| {
                const score = previous[left * columns + right];
                if (score < 0) continue;
                var left_delta: i32 = -1;
                while (left_delta <= 1) : (left_delta += 1) {
                    const next_left_signed = @as(i32, @intCast(left)) + left_delta;
                    if (next_left_signed < 0 or next_left_signed >= @as(i32, @intCast(columns))) continue;
                    const next_left: usize = @intCast(next_left_signed);
                    var right_delta: i32 = -1;
                    while (right_delta <= 1) : (right_delta += 1) {
                        const next_right_signed = @as(i32, @intCast(right)) + right_delta;
                        if (next_right_signed < 0 or next_right_signed >= @as(i32, @intCast(columns))) continue;
                        const next_right: usize = @intCast(next_right_signed);
                        var candidate = score + input[2 + row * columns + next_left];
                        if (next_left != next_right) candidate += input[2 + row * columns + next_right];
                        const slot = next_left * columns + next_right;
                        current[slot] = @max(current[slot], candidate);
                    }
                }
            }
        }
        previous = current;
    }
    var answer: i64 = -1;
    for (0..columns) |left| {
        for (0..columns) |right| answer = @max(answer, previous[left * columns + right]);
    }
    return answer;
}
