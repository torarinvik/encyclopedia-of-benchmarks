const MAX_INPUT: usize = 97;
const MAX_TEXT: usize = 64;
const BOARD_SIZE: usize = 30;
const MAX_OUTPUT: usize = 128;

fn parseBoard(input: [*c]const i64, length: usize, hole_a: *usize,
    hole_b: *usize, text_length: *usize, mode: *i64) bool {
    if (input == null or length < 32 or length > MAX_INPUT) return false;
    mode.* = input[0];
    if (mode.* != 0 and mode.* != 1) return false;
    var holes: usize = 0;
    for (0..BOARD_SIZE) |position| {
        const value = input[1 + position];
        if (position < 10 and value == 0) {
            if (holes == 0) hole_a.* = position else if (holes == 1) hole_b.* = position;
            holes += 1;
            continue;
        }
        if (value < 32 or value > 126) return false;
        for (0..position) |prior| {
            if (input[1 + prior] == value) return false;
        }
    }
    if (holes != 2) return false;
    const count = input[31];
    if (count < 0 or count > MAX_TEXT) return false;
    text_length.* = @intCast(count);
    return length == 32 + text_length.*;
}

fn findSymbol(input: [*c]const i64, value: i64) ?usize {
    for (0..BOARD_SIZE) |position| {
        if (input[1 + position] != 0 and input[1 + position] == value) return position;
    }
    return null;
}

fn measureDecode(input: [*c]const i64, text_length: usize, hole_a: usize,
    hole_b: usize, result_length: *usize) bool {
    var index: usize = 0;
    while (index < text_length) {
        const value = input[32 + index];
        if (value < '0' or value > '9') return false;
        const column: usize = @intCast(value - '0');
        if (input[1 + column] != 0) {
            result_length.* += 1;
            index += 1;
            continue;
        }
        if ((column != hole_a and column != hole_b) or index + 1 >= text_length) return false;
        const next = input[32 + index + 1];
        if (next < '0' or next > '9') return false;
        result_length.* += 1;
        index += 2;
    }
    return true;
}

export fn straddling_checkerboard_transducer(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    var hole_a: usize = 0;
    var hole_b: usize = 0;
    var text_length: usize = 0;
    var mode: i64 = -1;
    if (!parseBoard(input, length, &hole_a, &hole_b, &text_length, &mode)) return -1;

    var result_length: usize = 0;
    if (mode == 0) {
        for (0..text_length) |index| {
            const position = findSymbol(input, input[32 + index]) orelse return -1;
            result_length += if (position < 10) 1 else 2;
        }
    } else if (!measureDecode(input, text_length, hole_a, hole_b, &result_length)) {
        return -1;
    }
    if (result_length > MAX_OUTPUT) return -1;
    if (output == null or output_capacity < result_length) return -2;

    if (mode == 0) {
        var out: usize = 0;
        for (0..text_length) |index| {
            const position = findSymbol(input, input[32 + index]).?;
            if (position < 10) {
                output[out] = @intCast('0' + position);
                out += 1;
            } else {
                const row_digit = if (position < 20) hole_a else hole_b;
                output[out] = @intCast('0' + row_digit);
                output[out + 1] = @intCast('0' + position % 10);
                out += 2;
            }
        }
    } else {
        var index: usize = 0;
        var out: usize = 0;
        while (index < text_length) {
            const column: usize = @intCast(input[32 + index] - '0');
            if (input[1 + column] != 0) {
                output[out] = @intCast(input[1 + column]);
                index += 1;
            } else {
                const row: usize = if (column == hole_a) 1 else 2;
                const next_column: usize = @intCast(input[32 + index + 1] - '0');
                output[out] = @intCast(input[1 + row * 10 + next_column]);
                index += 2;
            }
            out += 1;
        }
    }
    return @intCast(result_length);
}
