module fannkuch;

fn long fannkuch(long* values, usz length) @export("fannkuch") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > 8) return -1;
    long n = values[0];
    long[8] perm = {0}, perm1 = {0}, count = {0};
    for (long i = 0; i < n; i++) perm1[i] = i;
    long r = n;
    long flips_max = 0;
    while (true) {
        while (r != 1) { count[r - 1] = r; r--; }
        if (perm1[0] != 0 && perm1[n - 1] != n - 1) {
            for (long i = 1; i < n; i++) perm[i] = perm1[i];
            long k = perm1[0], flips = 0;
            while (true) {
                long i = 1, j = k - 1;
                while (i < j) {
                    long tmp = perm[i]; perm[i] = perm[j]; perm[j] = tmp;
                    i++; j--;
                }
                flips++;
                j = perm[k]; perm[k] = k; k = j;
                if (k == 0) break;
            }
            if (flips_max < flips) flips_max = flips;
        }
        while (true) {
            if (r == n) return flips_max;
            long first = perm1[0];
            for (long i = 0; i < r; i++) perm1[i] = perm1[i + 1];
            perm1[r] = first;
            count[r]--;
            if (count[r] > 0) break;
            r++;
        }
    }
}
