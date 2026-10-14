const MAX_ROWS: usize = 30;
const HASH_MOD: i64 = 1_000_000_007;

export fn pascal_triangle_benchmark(values: [*]const i64, length: usize) i64 {
    if (length != 1) return -1;
    const row_count_value = values[0];
    if (row_count_value < 0 or row_count_value > MAX_ROWS) return -1;
    const row_count: usize = @intCast(row_count_value);
    var row: [MAX_ROWS]i64 = undefined;
    for (0..MAX_ROWS) |index| row[index] = 0;
    row[0] = 1;
    var hash: i64 = 0;
    for (0..row_count) |row_index| {
        var column = row_index;
        while (column > 0) {
            row[column] += row[column - 1];
            column -= 1;
        }
        for (0..row_index + 1) |col| {
            hash = @mod(hash * 31 + @mod(row[col], HASH_MOD), HASH_MOD);
        }
    }
    return hash;
}
