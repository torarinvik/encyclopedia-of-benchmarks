module wildcard_matching;

// Full-string wildcard matching for lowercase ASCII text.
fn long wildcard_matching(long* input, usz length) @export("wildcard_matching") {
    if (input == null || length < 2 || length > 35) return -1;
    if (input[0] < 0 || input[0] > 12 || input[1] < 0 || input[1] > 20) return -1;
    usz text_length = (usz)input[0];
    usz pattern_length = (usz)input[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz i = 0; i < text_length; i++) {
        if (input[2 + i] < 97 || input[2 + i] > 122) return -1;
    }
    usz pattern_start = 2 + text_length;
    for (usz j = 0; j < pattern_length; j++) {
        long token = input[pattern_start + j];
        if (!((token >= 97 && token <= 122) || token == 42 || token == 63)) return -1;
    }
    bool[273] dp = {};
    dp[0] = true;
    for (usz j = 1; j <= pattern_length; j++) {
        if (input[pattern_start + j - 1] == 42) dp[j] = dp[j - 1];
    }
    for (usz i = 1; i <= text_length; i++) {
        for (usz j = 1; j <= pattern_length; j++) {
            long token = input[pattern_start + j - 1];
            usz cell = i * 21 + j;
            if (token == input[1 + i] || token == 63) {
                dp[cell] = dp[cell - 22];
            } else if (token == 42) {
                dp[cell] = dp[cell - 21] || dp[cell - 1];
            }
        }
    }
    return dp[text_length * 21 + pattern_length] ? 1 : 0;
}
