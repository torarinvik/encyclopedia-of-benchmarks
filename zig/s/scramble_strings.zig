const MAX_LENGTH: usize = 8;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2 * MAX_LENGTH + 3;
const MEMO_SIZE: usize = 9 * 9 * 9;

fn scrambleRec(values: [*]const i64, base1: usize, base2: usize, start1: usize,
    start2: usize, span: usize, memo: [*]i64) i64 {
    const slot = (start1 * 9 + start2) * 9 + span;
    if (memo[slot] >= 0) return memo[slot];

    var same = true;
    for (0..span) |offset| {
        if (values[base1 + start1 + offset] != values[base2 + start2 + offset]) {
            same = false;
            break;
        }
    }
    if (same) {
        memo[slot] = 1;
        return 1;
    }

    var counts = [_]i64{0} ** 26;
    for (0..span) |offset| {
        const first_bucket: usize = @intCast(values[base1 + start1 + offset] - 97);
        const second_bucket: usize = @intCast(values[base2 + start2 + offset] - 97);
        counts[first_bucket] += 1;
        counts[second_bucket] -= 1;
    }
    for (counts) |count| {
        if (count != 0) {
            memo[slot] = 0;
            return 0;
        }
    }

    for (1..span) |split| {
        if (scrambleRec(values, base1, base2, start1, start2, split, memo) != 0 and
            scrambleRec(values, base1, base2, start1 + split, start2 + split, span - split, memo) != 0) {
            memo[slot] = 1;
            return 1;
        }
        if (scrambleRec(values, base1, base2, start1, start2 + span - split, split, memo) != 0 and
            scrambleRec(values, base1, base2, start1 + split, start2, span - split, memo) != 0) {
            memo[slot] = 1;
            return 1;
        }
    }
    memo[slot] = 0;
    return 0;
}

export fn scramble_strings(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = values.?;
    const n_value = input[0];
    if (n_value < 0 or n_value > @as(i64, @intCast(MAX_LENGTH))) return -1;
    const n: usize = @intCast(n_value);
    if (length != 2 * n + 1) return -1;
    for (1..length) |index| {
        if (input[index] < 97 or input[index] > 122) return -1;
    }

    var memo: [MEMO_SIZE]i64 = undefined;
    for (&memo) |*entry| entry.* = -1;
    return scrambleRec(input, 1, 1 + n, 0, 0, n, &memo);
}
