module count_different_palindromic_subsequences;

const usz MAX_LENGTH = 20;
const long MODULUS = 1000000007L;

fn long normalize(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

long count_different_palindromic_subsequences(long* input, usz length)
        @export("count_different_palindromic_subsequences") {
    if (input == null || length < 1 || length > MAX_LENGTH + 2) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_LENGTH || length != (usz)n_value + 1) return -1;
    usz n = (usz)n_value;
    int[MAX_LENGTH] symbols = zeroed;
    for (usz i = 0; i < n; i++) {
        if (input[i + 1] < 0 || input[i + 1] > 3) return -1;
        symbols[i] = (int)input[i + 1];
    }
    if (n == 0) return 0;

    int[MAX_LENGTH] next_equal = zeroed, previous_equal = zeroed;
    int[4] next_at = {MAX_LENGTH, MAX_LENGTH, MAX_LENGTH, MAX_LENGTH};
    int[4] previous_at = {-1, -1, -1, -1};
    for (usz i = n; i > 0;) {
        i--;
        int symbol = symbols[i];
        next_equal[i] = next_at[(usz)symbol];
        next_at[(usz)symbol] = (int)i;
    }
    for (usz i = 0; i < n; i++) {
        int symbol = symbols[i];
        previous_equal[i] = previous_at[(usz)symbol];
        previous_at[(usz)symbol] = (int)i;
    }
    long[MAX_LENGTH][MAX_LENGTH] dp = zeroed;
    for (usz i = 0; i < n; i++) dp[i][i] = 1;
    for (usz width = 2; width <= n; width++) {
        for (usz left = 0; left + width <= n; left++) {
            usz right = left + width - 1;
            long inner = width > 2 ? dp[left + 1][right - 1] : 0;
            if (symbols[left] != symbols[right]) {
                dp[left][right] = normalize(dp[left + 1][right] + dp[left][right - 1] - inner);
            } else {
                int first = next_equal[left], last = previous_equal[right];
                long value;
                if (first >= (int)right || last <= (int)left || first > last) value = 2 * inner + 2;
                else if (first == last) value = 2 * inner + 1;
                else {
                    long duplicates = (usz)(first + 1) <= (usz)(last - 1) ? dp[(usz)(first + 1)][(usz)(last - 1)] : 0;
                    value = 2 * inner - duplicates;
                }
                dp[left][right] = normalize(value);
            }
        }
    }
    return dp[0][n - 1];
}
