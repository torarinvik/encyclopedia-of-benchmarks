const MAX_N: usize = 14;
const MAX_DIAGS: usize = 2 * MAX_N - 1;
const EMPTY_OWNER: i32 = 101;
const MAX_OUTPUT_BYTES: usize = 80;

const QueensState = struct {
    n: usize,
    queen: [MAX_N]usize,
    file: [MAX_N]i32,
    forward_diag: [MAX_DIAGS]i32,
    backward_diag: [MAX_DIAGS]i32,
    solutions: u64,
};

fn findSolutions(state: *QueensState, level: usize) void {
    if (level == state.n) {
        state.solutions += 1;
        return;
    }
    const level_owner: i32 = @intCast(level);
    for (0..state.n) |file_index| {
        const forward = file_index + level;
        const backward = level - file_index + state.n - 1;
        if (state.file[file_index] >= level_owner and
            state.forward_diag[forward] >= level_owner and
            state.backward_diag[backward] >= level_owner)
        {
            state.queen[level] = file_index;
            state.file[file_index] = level_owner;
            state.forward_diag[forward] = level_owner;
            state.backward_diag[backward] = level_owner;
            findSolutions(state, level + 1);
            state.file[file_index] = EMPTY_OWNER;
            state.forward_diag[forward] = EMPTY_OWNER;
            state.backward_diag[backward] = EMPTY_OWNER;
        }
    }
}

fn appendText(output: [*]u8, position_input: usize, text: []const u8) usize {
    var position = position_input;
    for (text) |byte| {
        output[position] = byte;
        position += 1;
    }
    return position;
}

fn appendUnsigned(output: [*]u8, position_input: usize, value_input: u64) usize {
    var position = position_input;
    var reversed: [24]u8 = @splat(0);
    var count: usize = 0;
    var value = value_input;
    while (true) {
        reversed[count] = @intCast(48 + value % 10);
        count += 1;
        value /= 10;
        if (value == 0) break;
    }
    while (count > 0) {
        count -= 1;
        output[position] = reversed[count];
        position += 1;
    }
    return position;
}

fn renderOutput(n: usize, solutions: u64, output: [*]u8) usize {
    var position = appendUnsigned(output, 0, @intCast(n));
    if (n == 1) {
        position = appendText(output, position, " queen on a ");
    } else {
        position = appendText(output, position, " queens on a ");
    }
    position = appendUnsigned(output, position, @intCast(n));
    output[position] = 'x';
    position += 1;
    position = appendUnsigned(output, position, @intCast(n));
    position = appendText(output, position, " board...\n");
    if (solutions == 1) {
        position = appendText(output, position, "...there is 1 solution\n");
    } else {
        position = appendText(output, position, "...there are ");
        position = appendUnsigned(output, position, solutions);
        position = appendText(output, position, " solutions\n");
    }
    return position;
}

export fn queens(n: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (n < 1 or n > 14) return -1;
    const board_size: usize = @intCast(n);
    var state = QueensState{
        .n = board_size,
        .queen = @splat(0),
        .file = @splat(EMPTY_OWNER),
        .forward_diag = @splat(EMPTY_OWNER),
        .backward_diag = @splat(EMPTY_OWNER),
        .solutions = 0,
    };
    findSolutions(&state, 0);

    var formatted: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    const required = renderOutput(board_size, state.solutions, &formatted);
    if (output_opt == null) return -2;
    if (output_capacity < required) return -2;
    const output = output_opt.?;
    for (0..required) |index| output[index] = formatted[index];
    return @intCast(required);
}
