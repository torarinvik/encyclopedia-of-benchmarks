#include <stddef.h>
#include <stdint.h>

enum { MAX_LENGTH = 20, ALPHABET_SIZE = 4 };
static const int64_t MODULUS = INT64_C(1000000007);

static int64_t normalize(int64_t value)
{
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

int64_t count_different_palindromic_subsequences(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_LENGTH + 2) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_LENGTH || length != (size_t)n_value + 1) return -1;
    const size_t n = (size_t)n_value;
    int symbols[MAX_LENGTH];
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 0 || input[i + 1] >= ALPHABET_SIZE) return -1;
        symbols[i] = (int)input[i + 1];
    }
    if (n == 0) return 0;

    int next_equal[MAX_LENGTH], previous_equal[MAX_LENGTH];
    int next_at[ALPHABET_SIZE] = {MAX_LENGTH, MAX_LENGTH, MAX_LENGTH, MAX_LENGTH};
    int previous_at[ALPHABET_SIZE] = {-1, -1, -1, -1};
    for (size_t i = n; i > 0;) {
        --i;
        next_equal[i] = next_at[symbols[i]];
        next_at[symbols[i]] = (int)i;
    }
    for (size_t i = 0; i < n; ++i) {
        previous_equal[i] = previous_at[symbols[i]];
        previous_at[symbols[i]] = (int)i;
    }

    int64_t dp[MAX_LENGTH][MAX_LENGTH] = {{0}};
    for (size_t i = 0; i < n; ++i) dp[i][i] = 1;
    for (size_t width = 2; width <= n; ++width) {
        for (size_t left = 0; left + width <= n; ++left) {
            const size_t right = left + width - 1;
            const int64_t inner = width > 2 ? dp[left + 1][right - 1] : 0;
            if (symbols[left] != symbols[right]) {
                dp[left][right] = normalize(dp[left + 1][right] + dp[left][right - 1] - inner);
            } else {
                const int first = next_equal[left], last = previous_equal[right];
                int64_t value;
                if (first >= (int)right || last <= (int)left || first > last) value = 2 * inner + 2;
                else if (first == last) value = 2 * inner + 1;
                else {
                    const int64_t duplicates = first + 1 <= last - 1 ? dp[first + 1][last - 1] : 0;
                    value = 2 * inner - duplicates;
                }
                dp[left][right] = normalize(value);
            }
        }
    }
    return dp[0][n - 1];
}
