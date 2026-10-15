/// Track unmatched opening positions and reset after an unmatched close.
const MAX_LENGTH: usize = 4096;

export fn longest_valid_parentheses_stack(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and input == null)) return -1;
    for (0..length) |index| {
        if (input[index] != 40 and input[index] != 41) return -1;
    }

    var unmatched: [MAX_LENGTH + 1]isize = undefined;
    var top: usize = 0;
    unmatched[0] = -1;
    var best: usize = 0;
    for (0..length) |index| {
        if (input[index] == 40) {
            top += 1;
            unmatched[top] = @intCast(index);
        } else if (top == 0) {
            unmatched[0] = @intCast(index);
        } else {
            top -= 1;
            const start = unmatched[top];
            const current: usize = @intCast(@as(isize, @intCast(index)) - start);
            best = @max(best, current);
        }
    }
    return @intCast(best);
}
