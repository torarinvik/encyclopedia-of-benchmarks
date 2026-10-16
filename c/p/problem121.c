#include <stdint.h>

int64_t problem121(int64_t num_turns)
{
    if (num_turns < 1 || num_turns > 15) return -1;
    int64_t denominator = 1;
    for (int64_t turn = 2; turn <= num_turns + 1; ++turn) denominator *= turn;

    int64_t winning_weight = 0;
    int64_t sequence_count = 1;
    for (int64_t turn = 0; turn < num_turns; ++turn) sequence_count *= 2;
    for (int64_t mask = 0; mask < sequence_count; ++mask) {
        int64_t remaining = mask;
        int64_t blue = 0;
        int64_t weight = 1;
        for (int64_t turn = 0; turn < num_turns; ++turn) {
            if (remaining % 2 == 0) weight *= turn + 1;
            else ++blue;
            remaining /= 2;
        }
        if (2 * blue > num_turns) winning_weight += weight;
    }
    return denominator / winning_weight;
}
