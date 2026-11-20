module longest_common_increasing_subsequence;

const usz MAX_INPUT_LENGTH = 67;
const long MAX_SIDE = 32;

fn long longest_common_increasing_subsequence(long* input, usz length) @export("longest_common_increasing_subsequence") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n = input[0];
    long m = input[1];
    if (n < 0 || n > MAX_SIDE || m < 0 || m > MAX_SIDE || length != (usz)(2 + n + m)) return -1;
    for (usz index = 0; index < (usz)(n + m); index++) {
        if (input[2 + index] < -16 || input[2 + index] > 16) return -1;
    }

    long[32] ending_at;
    for (usz j = 0; j < 32; j++) ending_at[j] = 0;
    for (usz i = 0; i < (usz)n; i++) {
        long value = input[2 + i];
        long best_smaller = 0;
        for (usz j = 0; j < (usz)m; j++) {
            long other = input[2 + (usz)n + j];
            if (value > other && ending_at[j] > best_smaller) {
                best_smaller = ending_at[j];
            } else if (value == other && best_smaller + 1 > ending_at[j]) {
                ending_at[j] = best_smaller + 1;
            }
        }
    }
    long answer = 0;
    for (usz j = 0; j < (usz)m; j++) if (ending_at[j] > answer) answer = ending_at[j];
    return answer;
}
