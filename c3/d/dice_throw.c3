module dice_throw;

const long MAX_FACES = 8;
const long MAX_DICE = 8;
const long MAX_TARGET = 64;

fn long dice_throw(long* values, usz length) @export("dice_throw") {
    if (values == null || length != 3) return -1;
    long faces = values[0];
    long dice = values[1];
    long target = values[2];
    if (faces < 1 || faces > MAX_FACES || dice < 1 || dice > MAX_DICE || target < 0 || target > MAX_TARGET)
        return -1;

    long[9][65] table;
    for (long i = 0; i <= MAX_DICE; i++) {
        for (long j = 0; j <= MAX_TARGET; j++) table[i][j] = 0;
    }
    for (long total = 1; total <= faces && total <= target; total++) table[1][total] = 1;
    for (long die = 2; die <= dice; die++) {
        for (long total = 1; total <= target; total++) {
            for (long face = 1; face < total && face <= faces; face++) {
                table[die][total] += table[die - 1][total - face];
            }
        }
    }
    return table[dice][target];
}
