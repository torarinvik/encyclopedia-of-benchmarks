module problem117;

fn long problem117(long length) @export("problem117") {
    if (length < 0 || length > 67) return -1;
    long[68] ways = {0};
    ways[0] = 1;
    for (long row = 1; row <= length; row++) {
        ways[row] = ways[row - 1];
        if (row >= 2) ways[row] += ways[row - 2];
        if (row >= 3) ways[row] += ways[row - 3];
        if (row >= 4) ways[row] += ways[row - 4];
    }
    return ways[length];
}
