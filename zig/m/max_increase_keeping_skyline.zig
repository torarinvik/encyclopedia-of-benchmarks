/// Return the total allowable increase while preserving row and column skylines.
export fn max_increase_keeping_skyline(values: [*]const i64, length: usize) i64 {
    const max_grid_size = 50;
    if (length < 2 or length > 1 + max_grid_size * max_grid_size) return -1;
    if (values[0] < 2 or values[0] > max_grid_size) return -1;
    const size: usize = @intCast(values[0]);
    if (length != 1 + size * size) return -1;

    var row_max: [max_grid_size]u8 = @splat(0);
    var column_max: [max_grid_size]u8 = @splat(0);
    var tallest: u64 = 0;
    var height_sum: u32 = 0;
    for (0..size) |row| {
        var row_tallest: u8 = 0;
        const start = 1 + row * size;
        for (0..size) |column| {
            const value: u64 = @bitCast(values[start + column]);
            tallest = @max(tallest, value);
            height_sum +%= @truncate(value);
            const height: u8 = @truncate(value);
            row_tallest = @max(row_tallest, height);
            column_max[column] = @max(column_max[column], height);
        }
        row_max[row] = row_tallest;
    }
    if (tallest > 100) return -1;

    var skyline_sum: u32 = 0;
    if (size <= 10) {
        for (row_max[0..size]) |row_height| {
            for (column_max[0..size]) |column_height| {
                skyline_sum += @min(row_height, column_height);
            }
        }
    } else {
        var row_counts: [101]u8 = @splat(0);
        var column_counts: [101]u8 = @splat(0);
        var lowest: u8 = 100;
        for (0..size) |index| {
            lowest = @min(lowest, row_max[index], column_max[index]);
            row_counts[row_max[index]] += 1;
            column_counts[column_max[index]] += 1;
        }
        var rows_above: u32 = @intCast(size);
        var columns_above = rows_above;
        skyline_sum = rows_above * columns_above * lowest;
        for (lowest..@as(usize, @intCast(tallest))) |height| {
            rows_above -= row_counts[height];
            columns_above -= column_counts[height];
            skyline_sum += rows_above * columns_above;
        }
    }
    return @intCast(skyline_sum - height_sum);
}
