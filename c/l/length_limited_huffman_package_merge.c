/* Length-limited binary Huffman cost via package-merge node-set reduction. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SYMBOLS 12
#define MAX_LEVELS 16
#define MAX_ITEMS 32

int64_t length_limited_huffman_package_merge(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || length > 15) return -1;
    int64_t raw_n = input[0], raw_limit = input[1];
    if (raw_n < 2 || raw_n > MAX_SYMBOLS || raw_limit < 1 || raw_limit > 6 ||
        raw_n > (INT64_C(1) << raw_limit) || length != (size_t)(raw_n + 2))
        return -1;

    int n = (int)raw_n, limit = (int)raw_limit;
    int64_t weights[MAX_SYMBOLS];
    for (int i = 0; i < n; ++i) {
        weights[i] = input[i + 2];
        if (weights[i] < 0 || weights[i] > 1000000) return -1;
    }
    for (int i = 1; i < n; ++i) {
        int64_t key = weights[i];
        int j = i;
        while (j > 0 && key < weights[j - 1]) {
            weights[j] = weights[j - 1];
            --j;
        }
        weights[j] = key;
    }

    int64_t levels[MAX_LEVELS][MAX_ITEMS] = {{0}};
    int counts[MAX_LEVELS] = {0};
    for (int level = 0; level < limit; ++level) {
        counts[level] = n;
        for (int i = 0; i < n; ++i) levels[level][i] = weights[i];
    }

    int64_t remaining = (int64_t)(n - 1) << limit;
    int64_t total_cost = 0;
    int level = 0;
    while (remaining > 0) {
        while (level < MAX_LEVELS && counts[level] == 0) ++level;
        if (level >= MAX_LEVELS) return -1;

        int64_t width = INT64_C(1) << level;
        int64_t needed = remaining & -remaining;
        if (width > needed) return -1;

        int count = counts[level];
        if (width == needed) {
            total_cost += levels[level][0];
            for (int i = 1; i < count; ++i) levels[level][i - 1] = levels[level][i];
            --count;
            counts[level] = count;
            remaining -= width;
            if (remaining == 0) break;
        }

        int64_t packages[MAX_ITEMS];
        int package_count = count / 2;
        for (int i = 0; i < package_count; ++i)
            packages[i] = levels[level][2 * i] + levels[level][2 * i + 1];
        counts[level] = 0;

        int next_level = level + 1;
        if (next_level >= MAX_LEVELS || counts[next_level] + package_count > MAX_ITEMS)
            return -1;
        int64_t merged[MAX_ITEMS];
        int existing_count = counts[next_level];
        int package_index = 0, existing_index = 0, merged_count = 0;
        while (package_index < package_count && existing_index < existing_count) {
            if (packages[package_index] <= levels[next_level][existing_index])
                merged[merged_count++] = packages[package_index++];
            else
                merged[merged_count++] = levels[next_level][existing_index++];
        }
        while (package_index < package_count) merged[merged_count++] = packages[package_index++];
        while (existing_index < existing_count)
            merged[merged_count++] = levels[next_level][existing_index++];
        for (int i = 0; i < merged_count; ++i) levels[next_level][i] = merged[i];
        counts[next_level] = merged_count;
        level = next_level;
    }
    return total_cost;
}
