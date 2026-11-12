const MAX_SEQUENCE_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 132;

const HirschbergState = struct {
    forward: [MAX_SEQUENCE_LENGTH + 1]i32 = @splat(0),
    backward: [MAX_SEQUENCE_LENGTH + 1]i32 = @splat(0),
    result: [MAX_SEQUENCE_LENGTH]u8 = @splat(0),
    result_length: usize = 0,
};

fn lcsRow(input: []const i64, a_base: usize, a0: usize, a1: usize,
          b_base: usize, b0: usize, b1: usize,
          reverse_a: bool, reverse_b: bool,
          row: *[MAX_SEQUENCE_LENGTH + 1]i32) void {
    const width = b1 - b0;
    for (0..width + 1) |j| row[j] = 0;
    for (0..a1 - a0) |i| {
        const ai = if (reverse_a) input[a_base + a1 - 1 - i] else input[a_base + a0 + i];
        var diagonal: i32 = 0;
        for (1..width + 1) |j| {
            const above = row[j];
            const bj = if (reverse_b) input[b_base + b1 - j] else input[b_base + b0 + j - 1];
            if (ai == bj) row[j] = diagonal + 1 else if (row[j - 1] > row[j]) row[j] = row[j - 1];
            diagonal = above;
        }
    }
}

fn recoverLcs(input: []const i64, a_base: usize, a0: usize, a1: usize,
              b_base: usize, b0: usize, b1: usize, state: *HirschbergState) void {
    const a_length = a1 - a0;
    const b_length = b1 - b0;
    if (a_length == 0 or b_length == 0) return;
    if (a_length == 1) {
        const target = input[a_base + a0];
        for (b0..b1) |j| {
            if (input[b_base + j] == target) {
                state.result[state.result_length] = @intCast(target);
                state.result_length += 1;
                return;
            }
        }
        return;
    }

    const middle = a0 + a_length / 2;
    lcsRow(input, a_base, a0, middle, b_base, b0, b1, false, false, &state.forward);
    lcsRow(input, a_base, middle, a1, b_base, b0, b1, true, true, &state.backward);
    var split: usize = 0;
    var best_score: i32 = -1;
    for (0..b_length + 1) |j| {
        const score = state.forward[j] + state.backward[b_length - j];
        if (score > best_score) {
            best_score = score;
            split = j;
        }
    }
    recoverLcs(input, a_base, a0, middle, b_base, b0, b0 + split, state);
    recoverLcs(input, a_base, middle, a1, b_base, b0 + split, b1, state);
}

export fn hirschberg_lcs(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > MAX_SEQUENCE_LENGTH
        or values[1] < 0 or values[1] > MAX_SEQUENCE_LENGTH) return -1;
    const first_length: usize = @intCast(values[0]);
    const second_length: usize = @intCast(values[1]);
    if (length != 2 + first_length + second_length) return -1;
    for (values[2..]) |symbol| if (symbol < 0 or symbol > 127) return -1;

    const a_base: usize = if (first_length < second_length) 2 + first_length else 2;
    const b_base: usize = if (first_length < second_length) 2 else 2 + first_length;
    const a_length = @max(first_length, second_length);
    const b_length = @min(first_length, second_length);
    var state = HirschbergState{};
    recoverLcs(values, a_base, 0, a_length, b_base, 0, b_length, &state);
    if (output == null or capacity < state.result_length) return -2;
    const destination = output.?;
    for (0..state.result_length) |i| destination[i] = state.result[i];
    return @intCast(state.result_length);
}
