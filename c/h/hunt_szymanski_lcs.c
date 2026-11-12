/* Return the LCS length using Hunt-Szymanski matching positions and LIS tails. */
#include <stddef.h>
#include <stdint.h>

int64_t hunt_szymanski_lcs(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > 131) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    if (n_value < 0 || n_value > 64 || m_value < 0 || m_value > 64 ||
        length != (size_t)(2 + n_value + m_value)) return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    for (size_t i = 0; i < n + m; ++i) {
        if (input[2 + i] < 0 || input[2 + i] > 127) return -1;
    }

    int32_t right_positions[128 * 64];
    int32_t position_count[128] = {0};
    int32_t tails[64];
    for (size_t j = 0; j < m; ++j) {
        const size_t symbol = (size_t)input[2 + n + j];
        const int32_t count = position_count[symbol];
        right_positions[symbol * 64 + (size_t)count] = (int32_t)j;
        position_count[symbol] = count + 1;
    }

    int32_t tail_count = 0;
    for (size_t i = 0; i < n; ++i) {
        const size_t symbol = (size_t)input[2 + i];
        for (int32_t count = position_count[symbol]; count > 0; --count) {
            const int32_t position = right_positions[symbol * 64 + (size_t)(count - 1)];
            int32_t low = 0;
            int32_t high = tail_count;
            while (low < high) {
                const int32_t middle = low + (high - low) / 2;
                if (tails[middle] >= position) high = middle;
                else low = middle + 1;
            }
            if (low == tail_count) tails[tail_count++] = position;
            else tails[low] = position;
        }
    }
    return tail_count;
}
