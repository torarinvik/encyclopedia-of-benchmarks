const MAX_N: usize = 12_345;
const MAX_LEVELS: usize = 14;
const MAX_INPUT_LENGTH: usize = 12_347;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 12_348;

export fn sparse_table(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 12_344) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 3 or length > MAX_INPUT_LENGTH) return -1;
    const left_word = input[n + 1];
    const right_word = input[n + 2];
    if (left_word < 0 or right_word < left_word or right_word >= input[0]) return -1;
    const left: usize = @intCast(left_word);
    const right: usize = @intCast(right_word);

    var values: [MAX_N]i64 = @splat(0);
    for (0..n) |index| values[index] = input[index + 1];
    var logs: [MAX_N + 1]usize = @splat(0);
    for (2..n + 1) |size| logs[size] = logs[size / 2] + 1;
    var table: [MAX_LEVELS * MAX_N]i32 = @splat(0);
    for (0..n) |index| table[index] = @intCast(index);
    for (1..(logs[n] + 1)) |level| {
        const span = @as(usize, 1) << @intCast(level);
        const half = span >> 1;
        for (0..n - span + 1) |index| {
            const first: usize = @intCast(table[(level - 1) * MAX_N + index]);
            const second: usize = @intCast(table[(level - 1) * MAX_N + index + half]);
            table[level * MAX_N + index] = @intCast(if (values[first] <= values[second]) first else second);
        }
    }
    const query_length = right - left + 1;
    const level = logs[query_length];
    const span = @as(usize, 1) << @intCast(level);
    const first: usize = @intCast(table[level * MAX_N + left]);
    const second: usize = @intCast(table[level * MAX_N + right - span + 1]);
    return @intCast(if (values[first] <= values[second]) first else second);
}
