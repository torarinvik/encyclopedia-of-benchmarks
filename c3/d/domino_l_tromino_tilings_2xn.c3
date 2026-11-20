module domino_l_tromino_tilings_2xn;

import "core:c";

const usz MAX_WIDTH = 32;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long count_tilings(long width) {
    long state0 = 1, state1 = 0, state2 = 0, state3 = 0;
    for (long column = 0; column < width; column++) {
        long next0 = state0 + state3;
        long next1 = state0 + state2;
        long next2 = state0 + state1;
        long next3 = state0 + state1 + state2;
        state0 = next0; state1 = next1; state2 = next2; state3 = next3;
    }
    return state0;
}

fn long domino_l_tromino_tilings_2xn(long* input, usz length)
    @export("domino_l_tromino_tilings_2xn") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 0 || input[0] > (long)MAX_WIDTH) return -1;
    return count_tilings(input[0]);
}
