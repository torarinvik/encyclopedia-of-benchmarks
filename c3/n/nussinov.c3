module nussinov;

const usz MAX_N = 128;

fn long nussinov(long* values, usz length) @export("nussinov") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > (long)MAX_N) return -1;
    usz n = (usz)values[0];
    long[MAX_N] bases;
    long[MAX_N][MAX_N] table;
    for (usz i = 0; i < n; i++) {
        bases[i] = (long)((i + 1) % 4);
        for (usz j = 0; j < n; j++) table[i][j] = 0;
    }

    usz i = n;
    while (i > 0) {
        i--;
        for (usz j = i + 1; j < n; j++) {
            long score = table[i][j - 1];
            if (i + 1 < n) {
                if (table[i + 1][j] > score) score = table[i + 1][j];
                long inside = table[i + 1][j - 1];
                if (i < j - 1 && bases[i] + bases[j] == 3) inside++;
                if (inside > score) score = inside;
            }
            for (usz k = i + 1; k < j; k++) {
                long split = table[i][k] + table[k + 1][j];
                if (split > score) score = split;
            }
            table[i][j] = score;
        }
    }

    long checksum = 0;
    for (usz row = 0; row < n; row++)
        for (usz col = row; col < n; col++)
            checksum += table[row][col];
    return checksum;
}
