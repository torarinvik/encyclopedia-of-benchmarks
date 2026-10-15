module minimum_steps_to_one;

const long MAX_N = 10000;

fn long minimum_steps_to_one(long n) @export("minimum_steps_to_one") {
    if (n < 1 || n > MAX_N) return -1;
    long[MAX_N + 1] table;
    for (long index = 0; index <= n; index++) table[index] = n + 1;
    table[1] = 0;
    for (long i = 1; i < n; i++) {
        if (table[i + 1] > table[i] + 1) table[i + 1] = table[i] + 1;
        if (i * 2 <= n && table[i * 2] > table[i] + 1) table[i * 2] = table[i] + 1;
        if (i * 3 <= n && table[i * 3] > table[i] + 1) table[i * 3] = table[i] + 1;
    }
    return table[n];
}
