/// Myers furthest-reaching edit-graph search for a bounded byte script.
const MAX_SEQUENCE: usize = 16;
const MAX_DISTANCE: usize = 32;
const MAX_OUTPUT: usize = 48;
const OFFSET: isize = 33;
const DIAGONALS: usize = 67;

const Script = struct {
    bytes: [MAX_OUTPUT]u8,
    length: usize,
};

fn buildScript(input: [*c]const i64, n: usize, m: usize) Script {
    var frontier: [DIAGONALS]i32 = undefined;
    for (&frontier) |*entry| entry.* = -1;
    var trace: [MAX_DISTANCE + 1][DIAGONALS]i32 = undefined;
    for (&trace) |*row| {
        for (row.*) |*entry| entry.* = -1;
    }
    frontier[@intCast(OFFSET + 1)] = 0;

    var found_distance: usize = 0;
    var found_diagonal: isize = 0;
    var distance: isize = 0;
    const max_distance: isize = @intCast(n + m);
    search: while (distance <= max_distance) : (distance += 1) {
        var diagonal = -distance;
        while (diagonal <= distance) : (diagonal += 2) {
            const slot: usize = @intCast(OFFSET + diagonal);
            var x: isize = undefined;
            if (diagonal == -distance or
                (diagonal != distance and frontier[slot - 1] < frontier[slot + 1]))
            {
                x = @intCast(frontier[slot + 1]);
            } else {
                x = @as(isize, @intCast(frontier[slot - 1])) + 1;
            }
            var y = x - diagonal;
            while (x < @as(isize, @intCast(n)) and y < @as(isize, @intCast(m)) and
                input[@intCast(2 + x)] == input[@intCast(2 + @as(isize, @intCast(n)) + y)])
            {
                x += 1;
                y += 1;
            }
            frontier[slot] = @intCast(x);
            trace[@intCast(distance)][slot] = @intCast(x);
            if (x >= @as(isize, @intCast(n)) and y >= @as(isize, @intCast(m))) {
                found_distance = @intCast(distance);
                found_diagonal = diagonal;
                break :search;
            }
        }
    }

    var reverse_ops: [MAX_DISTANCE]u8 = undefined;
    var reverse_symbols: [MAX_DISTANCE]u8 = undefined;
    var path_length: usize = 0;
    var x: isize = @intCast(n);
    var y: isize = @intCast(m);
    var diagonal = found_diagonal;
    var remaining = found_distance;
    while (remaining > 0) {
        const d: isize = @intCast(remaining);
        const slot: usize = @intCast(OFFSET + diagonal);
        const previous_row = trace[remaining - 1];
        var previous_diagonal: isize = undefined;
        var previous_x: isize = undefined;
        var previous_y: isize = undefined;
        var snake_x: isize = undefined;
        var snake_y: isize = undefined;
        if (diagonal == -d or
            (diagonal != d and previous_row[slot - 1] < previous_row[slot + 1]))
        {
            previous_diagonal = diagonal + 1;
            previous_x = @intCast(previous_row[@intCast(OFFSET + previous_diagonal)]);
            previous_y = previous_x - previous_diagonal;
            snake_x = previous_x;
            snake_y = previous_y + 1;
            while (x > snake_x and y > snake_y) {
                reverse_ops[path_length] = 0;
                reverse_symbols[path_length] = 0;
                path_length += 1;
                x -= 1;
                y -= 1;
            }
            reverse_ops[path_length] = 2;
            reverse_symbols[path_length] = @intCast(input[@intCast(2 + @as(isize, @intCast(n)) + previous_y)]);
            path_length += 1;
        } else {
            previous_diagonal = diagonal - 1;
            previous_x = @intCast(previous_row[@intCast(OFFSET + previous_diagonal)]);
            previous_y = previous_x - previous_diagonal;
            snake_x = previous_x + 1;
            snake_y = previous_y;
            while (x > snake_x and y > snake_y) {
                reverse_ops[path_length] = 0;
                reverse_symbols[path_length] = 0;
                path_length += 1;
                x -= 1;
                y -= 1;
            }
            reverse_ops[path_length] = 1;
            reverse_symbols[path_length] = 0;
            path_length += 1;
        }
        x = previous_x;
        y = previous_y;
        diagonal = previous_diagonal;
        remaining -= 1;
    }

    const prefix: usize = @intCast(trace[0][@intCast(OFFSET)]);
    for (0..prefix) |_| {
        reverse_ops[path_length] = 0;
        reverse_symbols[path_length] = 0;
        path_length += 1;
    }
    var result: [MAX_OUTPUT]u8 = undefined;
    var written: usize = 0;
    for (0..path_length) |step_index| {
        const step = path_length - step_index - 1;
        const operation = reverse_ops[step];
        result[written] = operation;
        written += 1;
        if (operation == 2) {
            result[written] = reverse_symbols[step];
            written += 1;
        }
    }
    return .{ .bytes = result, .length = written };
}

export fn myers_ond_shortest_edit_script(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    output_capacity: usize,
) i64 {
    if (input == null or length < 2 or length > 2 + 2 * MAX_SEQUENCE) return -1;
    const n_value = input[0];
    const m_value = input[1];
    const max_sequence_i64: i64 = @intCast(MAX_SEQUENCE);
    if (n_value < 0 or n_value > max_sequence_i64 or
        m_value < 0 or m_value > max_sequence_i64) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + n + m) return -1;
    for (0..n + m) |i| {
        const symbol = input[2 + i];
        if (symbol < 0 or symbol > 255) return -1;
    }

    const script = buildScript(input, n, m);
    if (output == null or output_capacity < script.length) return -2;
    for (0..script.length) |i| output[i] = script.bytes[i];
    return @intCast(script.length);
}
