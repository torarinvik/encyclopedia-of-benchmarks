/* Elias–Fano encode-and-access checksum for a bounded monotone sequence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_HIGH_BITS (3 * MAX_N)

int64_t elias_fano_monotone_sequence(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_N + 3) return -1;
    int64_t raw_n = input[0], upper_bound = input[1];
    if (raw_n < 1 || raw_n > MAX_N || upper_bound < 0 || upper_bound > 1000000 ||
        raw_n > upper_bound + 1 || length != (size_t)(raw_n + 2))
        return -1;
    int n = (int)raw_n;

    int64_t values[MAX_N], low_parts[MAX_N];
    for (int i = 0; i < n; ++i) {
        int64_t value = input[i + 2];
        if (value < 0 || value > upper_bound || (i > 0 && value < values[i - 1])) return -1;
        values[i] = value;
    }

    int low_width = 0;
    int64_t low_scale = 1;
    while ((int64_t)n * (low_scale << 1) <= upper_bound + 1) {
        low_scale <<= 1;
        ++low_width;
    }
    const uint64_t low_mask = (UINT64_C(1) << low_width) - 1;
    for (int i = 0; i < n; ++i) low_parts[i] = (int64_t)((uint64_t)values[i] & low_mask);

    const int64_t high_length = (upper_bound >> low_width) + n;
    if (high_length < 1 || high_length > MAX_HIGH_BITS) return -1;
    uint64_t high_bits[(MAX_HIGH_BITS + 63) / 64] = {0};
    for (int i = 0; i < n; ++i) {
        int64_t position = (values[i] >> low_width) + i;
        if (position < 0 || position >= high_length) return -1;
        high_bits[position / 64] |= UINT64_C(1) << (position % 64);
    }

    int64_t checksum = 0;
    int item_index = 0;
    for (int64_t position = 0; position < high_length; ++position) {
        if (((high_bits[position / 64] >> (position % 64)) & UINT64_C(1)) == 0) continue;
        if (item_index >= n || position < item_index) return -1;
        int64_t high_part = position - item_index;
        int64_t decoded = (high_part << low_width) | low_parts[item_index];
        checksum += (int64_t)(item_index + 1) * decoded;
        ++item_index;
    }
    return item_index == n ? checksum : -1;
}
