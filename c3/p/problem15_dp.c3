module problem15_dp;

fn long problem15_dp(long grid_size) @export("problem15_dp") {
    if (grid_size < 0 || grid_size > 20) return -1;
    long[21][21] counts;
    for (long row = 0; row <= grid_size; row++) {
        for (long column = 0; column <= grid_size; column++) {
            counts[row][column] = 1;
        }
    }
    for (long row = 1; row <= grid_size; row++) {
        for (long column = 1; column <= grid_size; column++) {
            counts[row][column] = counts[row - 1][column] + counts[row][column - 1];
        }
    }
    return counts[grid_size][grid_size];
}
