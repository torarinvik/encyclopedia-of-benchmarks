module problem29;

fn long problem29(long limit) @export("problem29") {
    if (limit < 1 || limit > 100) return -1;
    if (limit == 1) return 0;
    long roots[101], exponents[101];
    bool seen[60701] = zeroed;
    long distinct = 0;
    for (long a = 2; a <= limit; a++) {
        roots[a] = a; exponents[a] = 1;
        for (long candidate_exponent = 2; candidate_exponent <= 6; candidate_exponent++) {
            for (long candidate_root = 2; candidate_root <= a; candidate_root++) {
                long power = 1;
                for (long step = 0; step < candidate_exponent; step++) {
                    power *= candidate_root;
                    if (power > a) break;
                }
                if (power == a && candidate_exponent > exponents[a]) {
                    roots[a] = candidate_root; exponents[a] = candidate_exponent;
                }
            }
        }
        for (long b = 2; b <= limit; b++) {
            long key = roots[a] * 601 + exponents[a] * b;
            if (!seen[key]) { seen[key] = true; distinct++; }
        }
    }
    return distinct;
}
