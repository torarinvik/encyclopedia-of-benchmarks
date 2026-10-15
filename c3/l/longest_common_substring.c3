module longest_common_substring;

const usz MAX_LENGTH = 256;

fn long longest_common_substring(long* input, usz length) @export("longest_common_substring") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > (long)MAX_LENGTH) return -1;
    usz first_length = (usz)input[0];
    if (first_length + 2 > length || input[first_length + 1] < 0 || input[first_length + 1] > (long)MAX_LENGTH) return -1;
    usz second_length = (usz)input[first_length + 1];
    if (length != first_length + second_length + 2) return -1;
    long* first = input + 1; long* second = input + first_length + 2;
    for (usz i = 0; i < first_length; i++) if (first[i] < 32 || first[i] > 126) return -1;
    for (usz i = 0; i < second_length; i++) if (second[i] < 32 || second[i] > 126) return -1;
    long[MAX_LENGTH + 1] dp;
    for (usz j = 0; j <= MAX_LENGTH; j++) dp[j] = 0;
    long best = 0;
    for (usz i = 1; i <= first_length; i++) {
        usz j = second_length;
        while (j > 0) {
            if (first[i - 1] == second[j - 1]) { dp[j] = dp[j - 1] + 1; if (dp[j] > best) best = dp[j]; }
            else dp[j] = 0;
            j--;
        }
    }
    return best;
}
