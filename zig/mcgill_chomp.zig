const std = @import("std");
const COLUMNS: usize = 7;

const Solver = struct {
    rows: usize,
    powers: [COLUMNS]usize,
    heights: [COLUMNS]usize,
    values: []u8,
};

fn encodeState(solver: *const Solver) usize {
    var encoded: usize = 0;
    for (0..COLUMNS) |column| encoded += solver.heights[column] * solver.powers[column];
    return encoded;
}

fn evaluateState(solver: *Solver) void {
    const state_id = encodeState(solver);
    var has_move = false;
    var winning = false;
    for (0..solver.rows) |row| {
        for (0..COLUMNS) |column| {
            var child_id: usize = 0;
            var changed = false;
            for (0..COLUMNS) |index| {
                var height = solver.heights[index];
                if (index >= column and height > row) {
                    height = row;
                    changed = true;
                }
                child_id += height * solver.powers[index];
            }
            if (!changed) continue;
            has_move = true;
            if (solver.values[child_id] == 0) winning = true;
        }
    }
    solver.values[state_id] = 0;
    if (!has_move or winning) solver.values[state_id] = 1;
}

fn enumerateStates(solver: *Solver, column: isize, minimum_height: usize) void {
    if (column < 0) {
        evaluateState(solver);
        return;
    }
    var height = minimum_height;
    while (height <= solver.rows) : (height += 1) {
        solver.heights[@intCast(column)] = height;
        enumerateStates(solver, column - 1, height);
    }
}

export fn mcgill_chomp(raw_rows: i64) i64 {
    if (raw_rows != 7 and raw_rows != 8) return -1;
    const rows: usize = @intCast(raw_rows);
    const base = rows + 1;
    var powers: [COLUMNS]usize = undefined;
    powers[0] = 1;
    for (1..COLUMNS) |column| powers[column] = powers[column - 1] * base;
    const state_space = powers[COLUMNS - 1] * base;
    const allocator = std.heap.page_allocator;
    const values = allocator.alloc(u8, state_space) catch return -1;
    defer allocator.free(values);
    @memset(values, 0);
    var solver = Solver{ .rows = rows, .powers = powers, .heights = @splat(0), .values = values };

    enumerateStates(&solver, @as(isize, @intCast(COLUMNS)) - 1, 0);
    var full_board_id: usize = 0;
    for (0..COLUMNS) |column| full_board_id += rows * solver.powers[column];
    return @intCast(solver.values[full_board_id]);
}
