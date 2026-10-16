module problem121;

fn long problem121(long num_turns) @export("problem121") {
    if (num_turns < 1 || num_turns > 15) return -1;
    long denominator = 1;
    for (long turn = 2; turn <= num_turns + 1; turn++) denominator *= turn;

    long winning_weight = 0;
    long sequence_count = 1;
    for (long turn = 0; turn < num_turns; turn++) sequence_count *= 2;
    for (long mask = 0; mask < sequence_count; mask++) {
        long remaining = mask, blue = 0, weight = 1;
        for (long turn = 0; turn < num_turns; turn++) {
            if (remaining % 2 == 0) weight *= turn + 1;
            else blue++;
            remaining /= 2;
        }
        if (2 * blue > num_turns) winning_weight += weight;
    }
    return denominator / winning_weight;
}
