module egg_dropping;

const usz MAX_EGGS = 12;
const usz MAX_FLOORS = 128;
const usz FLOOR_WIDTH = MAX_FLOORS + 1;
const long INVALID_RESULT = -9223372036854775807L - 1L;

fn long egg_dropping(long* input, usz length) @export("egg_dropping") {
    if (input == null || length != 2) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > (long)MAX_EGGS ||
        input[1] < 1 || input[1] > (long)MAX_FLOORS) return INVALID_RESULT;

    usz eggs = (usz)input[0];
    usz floors = (usz)input[1];
    long[(MAX_EGGS + 1) * FLOOR_WIDTH] dp = zeroed;

    for (usz egg = 1; egg <= eggs; egg++) dp[egg * FLOOR_WIDTH + 1] = 1;
    for (usz floor = 1; floor <= floors; floor++) dp[FLOOR_WIDTH + floor] = (long)floor;
    for (usz egg = 2; egg <= eggs; egg++) {
        for (usz floor = 2; floor <= floors; floor++) {
            long best = 9223372036854775807L;
            for (usz drop = 1; drop <= floor; drop++) {
                long breaks = dp[(egg - 1) * FLOOR_WIDTH + drop - 1];
                long survives = dp[egg * FLOOR_WIDTH + floor - drop];
                long worst = 1 + (breaks > survives ? breaks : survives);
                if (worst < best) best = worst;
            }
            dp[egg * FLOOR_WIDTH + floor] = best;
        }
    }
    return dp[eggs * FLOOR_WIDTH + floors];
}
