const MAX_ROWS: usize = 8;
const MAX_SOLUTIONS: usize = 256;

/// Choose the uncovered column with the fewest compatible rows, then branch on it.
fn search(columns: usize, row_count: usize, rows: *const [MAX_ROWS]u64,
    covered: u64, selected: u64, found: *[MAX_SOLUTIONS]bool,
    solution_count: *usize) void {
    const full_mask = (@as(u64, 1) << @intCast(columns)) - 1;
    if (covered == full_mask) {
        const index: usize = @intCast(selected);
        if (!found.*[index]) {
            found.*[index] = true;
            solution_count.* += 1;
        }
        return;
    }
    var best_column = columns;
    var best_count = row_count + 1;
    for (0..columns) |column| {
        const bit = @as(u64, 1) << @intCast(column);
        if ((covered & bit) != 0) continue;
        var candidates: usize = 0;
        for (0..row_count) |row| {
            if ((rows.*[row] & bit) != 0 and (rows.*[row] & covered) == 0) candidates += 1;
        }
        if (candidates == 0) return;
        if (candidates < best_count) {
            best_column = column;
            best_count = candidates;
        }
    }
    const bit = @as(u64, 1) << @intCast(best_column);
    for (0..row_count) |row| {
        const row_mask = rows.*[row];
        if ((row_mask & bit) != 0 and (row_mask & covered) == 0) {
            search(columns, row_count, rows, covered | row_mask,
                selected | (@as(u64, 1) << @intCast(row)), found, solution_count);
        }
    }
}

/// Count exact covers and emit selected-row bitmasks in ascending order.
export fn dancing_links(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 10) return -1;
    const universe_value = input[0];
    const row_count_value = input[1];
    if (universe_value < 1 or universe_value > 8 or row_count_value < 0 or row_count_value > 8) return -1;
    const universe: usize = @intCast(universe_value);
    const row_count: usize = @intCast(row_count_value);
    if (length != row_count + 2) return -1;
    const full_mask: i64 = (@as(i64, 1) << @intCast(universe)) - 1;
    var rows: [MAX_ROWS]u64 = @splat(0);
    for (0..row_count) |row| {
        const mask = input[row + 2];
        if (mask <= 0 or (mask & ~full_mask) != 0) return -1;
        rows[row] = @intCast(mask);
    }
    var found: [MAX_SOLUTIONS]bool = @splat(false);
    var solution_count: usize = 0;
    search(universe, row_count, &rows, 0, 0, &found, &solution_count);
    if (output_capacity < solution_count or (solution_count != 0 and output == null)) return -2;
    var position: usize = 0;
    for (0..MAX_SOLUTIONS) |selection| {
        if (found[selection]) {
            output[position] = @intCast(selection);
            position += 1;
        }
    }
    return @intCast(solution_count);
}
