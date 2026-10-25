const MAX_ROWS: usize = 8;
const MAX_COLS: usize = 8;
const MAX_INPUT: usize = 67;

export fn scimark2_sor(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT) return -1;
    const row_value = input[0];
    const col_value = input[1];
    const iteration_value = input[2];
    if (row_value < 2 or row_value > 8 or col_value < 2 or col_value > 8 or iteration_value < 0 or iteration_value > 8) return -1;
    const rows: usize = @intCast(row_value);
    const cols: usize = @intCast(col_value);
    const iterations: usize = @intCast(iteration_value);
    if (length != 3 + rows * cols) return -1;
    var grid = [_]i64{0} ** (MAX_ROWS * MAX_COLS);
    for (0..rows * cols) |i| {
        const value = input[3 + i];
        if (value < -1000 or value > 1000) return -1;
        grid[i] = value;
    }
    for (0..iterations) |_| {
        for (1..rows - 1) |row| {
            for (1..cols - 1) |col| {
                const index = row * cols + col;
                const neighbors = grid[index - cols] + grid[index + cols] + grid[index - 1] + grid[index + 1];
                const numerator = 1250 * neighbors - 1000 * grid[index];
                grid[index] = @divTrunc(numerator, 4000);
            }
        }
    }
    var checksum: i64 = 0;
    for (0..rows * cols) |i| checksum += @as(i64, @intCast(i + 1)) * grid[i];
    return checksum;
}
