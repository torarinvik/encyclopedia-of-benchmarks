module egg_dropping_puzzle;

const usz MAX_EGGS = 8;
const usz MAX_FLOORS = 32;

fn long egg_dropping_puzzle(long* input, usz length) @export("egg_dropping_puzzle") {
    if (input == null || length != 2) return -1;
    long eggs_value = input[0];
    long floors_value = input[1];
    if (eggs_value < 1 || eggs_value > (long)MAX_EGGS || floors_value < 1 || floors_value > (long)MAX_FLOORS) return -1;

    usz eggs = (usz)eggs_value;
    usz floors = (usz)floors_value;
    long[MAX_EGGS + 1][MAX_FLOORS + 1] dp = zeroed;
    for (usz egg = 1; egg <= eggs; egg += 1) dp[egg][1] = 1;
    for (usz floor_count = 1; floor_count <= floors; floor_count += 1) dp[1][floor_count] = (long)floor_count;

    for (usz egg = 2; egg <= eggs; egg += 1) {
        for (usz floor_count = 2; floor_count <= floors; floor_count += 1) {
            long best = (long)MAX_FLOORS + 1;
            for (usz drop_floor = 1; drop_floor <= floor_count; drop_floor += 1) {
                long broken = dp[egg - 1][drop_floor - 1];
                long survives = dp[egg][floor_count - drop_floor];
                long worst = broken;
                if (survives > worst) worst = survives;
                long candidate = worst + 1;
                if (candidate < best) best = candidate;
            }
            dp[egg][floor_count] = best;
        }
    }
    return dp[eggs][floors];
}
