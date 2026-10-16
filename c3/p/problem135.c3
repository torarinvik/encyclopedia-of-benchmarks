// Count values through limit with exactly ten valid arithmetic-progression solutions.
module problem135;

const long MAX_LIMIT = 1000000;

fn long problem135(long limit) @export("problem135") {
    if (limit > MAX_LIMIT) return -1;
    if (limit < 0) return 0;
    u8[1000001] frequency = {0};
    for (long first_term = 1; first_term <= limit; first_term++) {
        for (long n = first_term; n <= limit; n += first_term) {
            long common_difference = first_term + n / first_term;
            if (common_difference % 4 != 0) continue;
            common_difference /= 4;
            if (first_term > common_difference && first_term < 4 * common_difference && frequency[n] < 11)
                frequency[n]++;
        }
    }
    long count = 0;
    for (long n = 1; n <= limit; n++) if (frequency[n] == 10) count++;
    return count;
}
