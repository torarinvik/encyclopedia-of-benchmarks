const MAX_WIDTH: i64 = 64;
const MAX_GENERATIONS: i64 = 64;

export fn generate_rule_30_grid(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    const width_value = input[0];
    const generations_value = input[1];
    if (width_value < 1 or width_value > MAX_WIDTH or
        generations_value < 1 or generations_value > MAX_GENERATIONS) return -1;
    const width: usize = @intCast(width_value);
    const generations: usize = @intCast(generations_value);
    const output_count = width * generations;
    if (output_capacity < output_count or output == null) return -2;

    var current = [_]i64{0} ** 64;
    var next = [_]i64{0} ** 64;
    current[width / 2] = 1;
    for (0..width) |column| output[column] = @intCast(current[column]);
    for (1..generations) |generation| {
        for (0..width) |column| {
            const left = if (column > 0) current[column - 1] else 0;
            const right = if (column + 1 < width) current[column + 1] else 0;
            const pattern: u5 = @intCast(left * 4 + current[column] * 2 + right);
            next[column] = @intCast((@as(u32, 30) >> pattern) & 1);
        }
        for (0..width) |column| {
            current[column] = next[column];
            output[generation * width + column] = @intCast(next[column]);
        }
    }
    return @intCast(output_count);
}
