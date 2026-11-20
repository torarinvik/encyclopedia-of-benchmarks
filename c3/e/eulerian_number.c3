module eulerian_number;

const long MAX_N = 20;

long eulerian_number(long *values, usz length) @export("eulerian_number") {
    if (values == null || length != 2) return -1;
    long n = values[0], target = values[1];
    if (n < 0 || n > MAX_N || target < 0 || (n == 0 ? target != 0 : target >= n))
        return -1;

    long previous[21] = {};
    long current[21] = {};
    previous[0] = 1;
    for (long row = 1; row <= n; row++) {
        for (long k = 0; k < row; k++) {
            long same = previous[k];
            long fewer = k == 0 ? 0 : previous[k - 1];
            current[k] = (k + 1) * same + (row - k) * fewer;
        }
        for (usz index = 0; index < 21; index++) {
            previous[index] = current[index];
            current[index] = 0;
        }
    }
    return previous[target];
}
