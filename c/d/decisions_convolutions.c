#include <stddef.h>
#include <stdint.h>

#define MAX_DECISIONS 64
#define MAX_CRITERIA 16
#define MAX_VALUE INT64_C(100000)

int64_t decisions_convolutions(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3) return -1;
    int64_t method = input[0], n_value = input[1], m_value = input[2];
    if ((method != 0 && method != 1) || n_value < 1 || n_value > MAX_DECISIONS
        || m_value < 1 || m_value > MAX_CRITERIA) return -1;
    size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 3 + m + n * m) return -1;
    for (size_t j = 0; j < m; ++j)
        if (input[3 + j] < -MAX_VALUE || input[3 + j] > MAX_VALUE) return -1;
    for (size_t i = 0; i < n * m; ++i)
        if (input[3 + m + i] < -MAX_VALUE || input[3 + m + i] > MAX_VALUE) return -1;
    int64_t best_score = 0;
    size_t best_index = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t score = 0;
        for (size_t j = 0; j < m; ++j) {
            int64_t product = input[3 + m + i * m + j] * input[3 + j];
            if (method == 0) score += product;
            else if (j == 0 || product < score) score = product;
        }
        if (i == 0 || score > best_score) { best_score = score; best_index = i; }
    }
    return (int64_t)best_index;
}
