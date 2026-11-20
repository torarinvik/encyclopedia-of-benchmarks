#include <stddef.h>
#include <stdint.h>

enum { MAX_WIDTH = 32, MAX_PARSEABLE_LENGTH = 2 };

static int64_t count_tilings(int64_t width) {
    int64_t state0 = 1, state1 = 0, state2 = 0, state3 = 0;
    for (int64_t column = 0; column < width; ++column) {
        const int64_t next0 = state0 + state3;
        const int64_t next1 = state0 + state2;
        const int64_t next2 = state0 + state1;
        const int64_t next3 = state0 + state1 + state2;
        state0 = next0; state1 = next1; state2 = next2; state3 = next3;
    }
    return state0;
}

int64_t domino_l_tromino_tilings_2xn(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 0 || input[0] > MAX_WIDTH) return -1;
    return count_tilings(input[0]);
}
