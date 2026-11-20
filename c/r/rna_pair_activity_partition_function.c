#include <stddef.h>
#include <stdint.h>

#define MAX_SEQUENCE_LENGTH 16
#define MAX_PARSEABLE_LENGTH 122

static size_t pair_input_index(size_t n, size_t left, size_t right)
{
    const size_t preceding = left * (2 * n - left - 1) / 2;
    return 1 + preceding + (right - left - 1);
}

int64_t rna_pair_activity_partition_function(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_SEQUENCE_LENGTH) return -1;
    const size_t n = (size_t)input[0];
    const size_t expected_length = n == 0 ? 1 : 1 + n * (n - 1) / 2;
    if (length != expected_length) return -1;
    for (size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] > 3) return -1;
    if (n == 0) return 1;

    int64_t table[MAX_SEQUENCE_LENGTH][MAX_SEQUENCE_LENGTH] = {{0}};
    for (size_t span = 1; span <= n; ++span) {
        for (size_t left = 0; left + span <= n; ++left) {
            const size_t right = left + span - 1;
            int64_t total = left == right ? 1 : table[left][right - 1];
            for (size_t partner = left; partner < right; ++partner) {
                const int64_t activity = input[pair_input_index(n, partner, right)];
                const int64_t before = partner == left ? 1 : table[left][partner - 1];
                const int64_t inside = partner + 1 >= right ? 1 : table[partner + 1][right - 1];
                total += before * inside * activity;
            }
            table[left][right] = total;
        }
    }
    return table[0][n - 1];
}
