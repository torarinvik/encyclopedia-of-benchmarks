export fn problem121(num_turns: i64) i64 {
    if (num_turns < 1 or num_turns > 15) return -1;
    var denominator: i64 = 1;
    var turn: i64 = 2;
    while (turn <= num_turns + 1) : (turn += 1) denominator *= turn;
    var sequence_count: i64 = 1;
    turn = 0;
    while (turn < num_turns) : (turn += 1) sequence_count *= 2;
    var winning_weight: i64 = 0;
    var mask: i64 = 0;
    while (mask < sequence_count) : (mask += 1) {
        var remaining = mask;
        var blue: i64 = 0;
        var weight: i64 = 1;
        turn = 0;
        while (turn < num_turns) : (turn += 1) {
            if (@mod(remaining, 2) == 0) weight *= turn + 1 else blue += 1;
            remaining = @divTrunc(remaining, 2);
        }
        if (2 * blue > num_turns) winning_weight += weight;
    }
    return @divTrunc(denominator, winning_weight);
}
