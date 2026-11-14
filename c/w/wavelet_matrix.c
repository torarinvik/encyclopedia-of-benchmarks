#include <stddef.h>
#include <stdint.h>

typedef struct {
    int zero_prefix[11][65];
    int zero_count[11];
} wavelet_matrix_data;

static int count_less(const wavelet_matrix_data *matrix, int left, int right, int value) {
    int answer = 0;
    for (int level = 0; level < 11; ++level) {
        int left_zero = matrix->zero_prefix[level][left];
        int right_zero = matrix->zero_prefix[level][right];
        if ((value >> (10 - level)) & 1) {
            answer += right_zero - left_zero;
            left = matrix->zero_count[level] + left - left_zero;
            right = matrix->zero_count[level] + right - right_zero;
        } else {
            left = left_zero;
            right = right_zero;
        }
    }
    return answer;
}

int64_t wavelet_matrix(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || values[0] < 1 || values[0] > 64) return -1;
    int n = (int)values[0];
    if (length < (size_t)n + 2) return -1;
    for (int i = 0; i < n; ++i) if (values[1 + i] < -1000 || values[1 + i] > 1000) return -1;
    int64_t qv = values[n + 1];
    if (qv < 0 || qv > 128 || length != (size_t)(n + 2 + 5 * qv)) return -1;
    wavelet_matrix_data matrix;
    int current[64], scratch[64];
    for (int i = 0; i < n; ++i) current[i] = (int)values[1 + i] + 1000;
    for (int level = 0; level < 11; ++level) {
        int bit = 10 - level;
        matrix.zero_prefix[level][0] = 0;
        for (int i = 0; i < n; ++i)
            matrix.zero_prefix[level][i + 1] = matrix.zero_prefix[level][i] + (((current[i] >> bit) & 1) == 0);
        int zeros = matrix.zero_prefix[level][n], left = 0, right = zeros;
        matrix.zero_count[level] = zeros;
        for (int i = 0; i < n; ++i) {
            if (((current[i] >> bit) & 1) == 0) scratch[left++] = current[i];
            else scratch[right++] = current[i];
        }
        for (int i = 0; i < n; ++i) current[i] = scratch[i];
    }
    int64_t total = 0;
    for (int j = 0; j < (int)qv; ++j) {
        const int64_t *query = values + n + 2 + 5*j;
        int64_t op = query[0], a = query[1], b = query[2], c = query[3], d = query[4];
        int answer;
        if (op == 0) {
            if (a < -1000 || a > 1000 || b < -1 || b >= n) return -1;
            int x = (int)a + 1000, right = (int)b + 1;
            answer = count_less(&matrix, 0, right, x + 1) - count_less(&matrix, 0, right, x);
        } else if (op == 1) {
            if (a < 0 || a > b || b >= n || c < 0 || c > b - a) return -1;
            int left = (int)a, right = (int)b + 1, kth = (int)c, key = 0;
            for (int level = 0; level < 11; ++level) {
                int left_zero = matrix.zero_prefix[level][left];
                int right_zero = matrix.zero_prefix[level][right];
                int zeros = right_zero - left_zero;
                if (kth < zeros) { left = left_zero; right = right_zero; }
                else {
                    kth -= zeros;
                    key |= 1 << (10 - level);
                    left = matrix.zero_count[level] + left - left_zero;
                    right = matrix.zero_count[level] + right - right_zero;
                }
            }
            answer = key - 1000;
        } else if (op == 2) {
            if (a < 0 || a > b || b >= n || c < -1000 || d > 1000 || c > d) return -1;
            answer = count_less(&matrix, (int)a, (int)b + 1, (int)d + 1001)
                   - count_less(&matrix, (int)a, (int)b + 1, (int)c + 1000);
        } else return -1;
        total += (int64_t)(j + 1) * (answer + INT64_C(1000001));
    }
    return total;
}
