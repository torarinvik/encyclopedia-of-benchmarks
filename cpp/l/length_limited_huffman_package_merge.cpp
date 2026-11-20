/* Length-limited binary Huffman cost via package-merge node-set reduction. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_symbols = 12;
constexpr int max_levels = 16;
constexpr int max_items = 32;
}

extern "C" std::int64_t length_limited_huffman_package_merge(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > 15) return -1;
    const std::int64_t raw_n = input[0], raw_limit = input[1];
    if (raw_n < 2 || raw_n > max_symbols || raw_limit < 1 || raw_limit > 6 ||
        raw_n > (std::int64_t{1} << raw_limit) ||
        length != static_cast<std::size_t>(raw_n + 2)) return -1;

    const int n = static_cast<int>(raw_n), limit = static_cast<int>(raw_limit);
    std::int64_t weights[max_symbols]{};
    for (int i = 0; i < n; ++i) {
        weights[i] = input[i + 2];
        if (weights[i] < 0 || weights[i] > 1'000'000) return -1;
    }
    for (int i = 1; i < n; ++i) {
        const std::int64_t key = weights[i];
        int j = i;
        while (j > 0 && key < weights[j - 1]) {
            weights[j] = weights[j - 1];
            --j;
        }
        weights[j] = key;
    }

    std::int64_t levels[max_levels][max_items]{};
    int counts[max_levels]{};
    for (int level = 0; level < limit; ++level) {
        counts[level] = n;
        for (int i = 0; i < n; ++i) levels[level][i] = weights[i];
    }

    std::int64_t remaining = static_cast<std::int64_t>(n - 1) << limit;
    std::int64_t total_cost = 0;
    int level = 0;
    while (remaining > 0) {
        while (level < max_levels && counts[level] == 0) ++level;
        if (level >= max_levels) return -1;

        const std::int64_t width = std::int64_t{1} << level;
        const std::int64_t needed = remaining & -remaining;
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

        std::int64_t packages[max_items]{};
        const int package_count = count / 2;
        for (int i = 0; i < package_count; ++i)
            packages[i] = levels[level][2 * i] + levels[level][2 * i + 1];
        counts[level] = 0;

        const int next_level = level + 1;
        if (next_level >= max_levels || counts[next_level] + package_count > max_items) return -1;
        std::int64_t merged[max_items]{};
        const int existing_count = counts[next_level];
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
