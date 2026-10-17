/* Construct the source-compatible shortest common supersequence. */
#include <stddef.h>
#include <stdint.h>

int64_t shortest_common_supersequence(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > 130) return -1;
    const int64_t m_value = input[0], n_value = input[1];
    if (m_value < 0 || m_value > 64 || n_value < 0 || n_value > 64) return -1;
    const size_t m = (size_t)m_value, n = (size_t)n_value;
    if (length != 2 + m + n) return -1;
    for (size_t index = 0; index < m + n; ++index)
        if (input[2 + index] < 32 || input[2 + index] > 126) return -1;

    int64_t lcs[65][65] = {{0}};
    for (size_t i = 1; i <= m; ++i) {
        for (size_t j = 1; j <= n; ++j) {
            if (input[1 + i] == input[1 + m + j])
                lcs[i][j] = lcs[i - 1][j - 1] + 1;
            else
                lcs[i][j] = lcs[i - 1][j] > lcs[i][j - 1]
                    ? lcs[i - 1][j] : lcs[i][j - 1];
        }
    }

    uint8_t reversed[128];
    size_t used = 0, i = m, j = n;
    while (i > 0 && j > 0) {
        if (input[1 + i] == input[1 + m + j]) {
            reversed[used++] = (uint8_t)input[1 + i];
            --i;
            --j;
        } else if (lcs[i - 1][j] > lcs[i][j - 1]) {
            reversed[used++] = (uint8_t)input[1 + i];
            --i;
        } else {
            /* The pinned implementations choose Y when the LCS values tie. */
            reversed[used++] = (uint8_t)input[1 + m + j];
            --j;
        }
    }
    while (i > 0) reversed[used++] = (uint8_t)input[1 + i--];
    while (j > 0) reversed[used++] = (uint8_t)input[1 + m + j--];

    if (output == NULL || capacity < used) return -2;
    for (size_t index = 0; index < used; ++index)
        output[index] = reversed[used - 1 - index];
    return (int64_t)used;
}
