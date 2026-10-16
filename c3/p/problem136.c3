module problem136;

fn long problem136(long n_limit) @export("problem136") {
    if (n_limit > 100000) return -1;
    if (n_limit <= 0) return 0;
    u8[100000] solutions = {0};
    long max_delta = (n_limit + 1) / 4;
    for (long delta = 1; delta <= max_delta; delta++) {
        for (long y = 4 * delta - 1; y > delta; y--) {
            long n = y * (4 * delta - y);
            if (n >= n_limit) break;
            if (solutions[n] < 2) solutions[n]++;
        }
    }
    long answer = 0;
    for (long n = 0; n < n_limit; n++) if (solutions[n] == 1) answer++;
    return answer;
}
