/// Bottom-up minimum-square-count dynamic programming, bounded to 4096.
export fn minimum_squares_to_represent_a_number(input: i64) i64 {
    if (input < 0 or input > 4096) return -1;
    if (input == 0) return 1;

    var answers: [4097]i64 = @splat(-1);
    answers[0] = 0;
    const limit: usize = @intCast(input);
    for (1..limit + 1) |value| {
        var best: i64 = 9223372036854775807;
        var root: usize = 1;
        while (root <= value / root) : (root += 1) {
            const candidate = 1 + answers[value - root * root];
            if (candidate < best) best = candidate;
        }
        answers[value] = best;
    }
    return answers[limit];
}
