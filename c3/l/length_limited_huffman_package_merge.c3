module length_limited_huffman_package_merge;

const int MAX_SYMBOLS = 12;
const int MAX_LEVELS = 16;
const int MAX_ITEMS = 32;

fn long length_limited_huffman_package_merge(long* input, usz length)
        @export("length_limited_huffman_package_merge") {
    if (input == null || length < 4 || length > 15) return -1;
    long raw_n = input[0], raw_limit = input[1];
    if (raw_n < 2 || raw_n > MAX_SYMBOLS || raw_limit < 1 || raw_limit > 6 ||
        raw_n > (long)(1 << (int)raw_limit) || length != (usz)(raw_n + 2)) return -1;

    int n = (int)raw_n, limit = (int)raw_limit;
    long[MAX_SYMBOLS] weights = zeroed;
    for (int i = 0; i < n; i += 1) {
        weights[i] = input[i + 2];
        if (weights[i] < 0 || weights[i] > 1000000) return -1;
    }
    for (int i = 1; i < n; i += 1) {
        long key = weights[i];
        int j = i;
        while (j > 0 && key < weights[j - 1]) {
            weights[j] = weights[j - 1];
            j -= 1;
        }
        weights[j] = key;
    }

    long[MAX_LEVELS][MAX_ITEMS] levels = zeroed;
    int[MAX_LEVELS] counts = zeroed;
    for (int level = 0; level < limit; level += 1) {
        counts[level] = n;
        for (int i = 0; i < n; i += 1) levels[level][i] = weights[i];
    }

    long remaining = (long)(n - 1) << limit;
    long total_cost = 0;
    int level = 0;
    while (remaining > 0) {
        while (level < MAX_LEVELS && counts[level] == 0) level += 1;
        if (level >= MAX_LEVELS) return -1;

        long width = (long)1 << level;
        long needed = remaining & -remaining;
        if (width > needed) return -1;

        int count = counts[level];
        if (width == needed) {
            total_cost += levels[level][0];
            for (int i = 1; i < count; i += 1) levels[level][i - 1] = levels[level][i];
            count -= 1;
            counts[level] = count;
            remaining -= width;
            if (remaining == 0) break;
        }

        long[MAX_ITEMS] packages = zeroed;
        int package_count = count / 2;
        for (int i = 0; i < package_count; i += 1)
            packages[i] = levels[level][2 * i] + levels[level][2 * i + 1];
        counts[level] = 0;

        int next_level = level + 1;
        if (next_level >= MAX_LEVELS || counts[next_level] + package_count > MAX_ITEMS)
            return -1;
        long[MAX_ITEMS] merged = zeroed;
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
        for (int i = 0; i < merged_count; i += 1) levels[next_level][i] = merged[i];
        counts[next_level] = merged_count;
        level = next_level;
    }
    return total_cost;
}
