module entringer_number;

long entringer_number(long* values, usz length) @export("entringer_number") {
    if (values == null || length != 2) return -1;
    long n = values[0], target = values[1];
    if (n < 0 || n > 12 || target < 0 || target > n) return -1;
    long previous[13] = {1};
    long current[13] = {};
    for (long row = 1; row <= n; row++) {
        current[0] = 0;
        for (long col = 1; col <= row; col++)
            current[col] = current[col - 1] + previous[row - col];
        for (usz i = 0; i < 13; i++) {
            previous[i] = current[i];
            current[i] = 0;
        }
    }
    return previous[target];
}
