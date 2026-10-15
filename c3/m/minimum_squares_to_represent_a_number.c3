module minimum_squares_to_represent_a_number;

// Bottom-up minimum-square-count dynamic programming, bounded to 4096.
fn long minimum_squares_to_represent_a_number(long input) @export("minimum_squares_to_represent_a_number")
{
    if (input < 0 || input > 4096) return -1;
    if (input == 0) return 1;

    long[4097] answers;
    for (long index = 0; index <= input; ++index) answers[index] = -1;
    answers[0] = 0;
    for (long value = 1; value <= input; ++value) {
        long best = 9223372036854775807L;
        for (long root = 1; root <= value / root; ++root) {
            long candidate = 1 + answers[value - root * root];
            if (candidate < best) best = candidate;
        }
        answers[value] = best;
    }
    return answers[input];
}
