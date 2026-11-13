#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_keys = 24, max_queries = 24, universe_bits = 16;
constexpr std::size_t levels_count = universe_bits + 1, max_parseable = 51, max_input = 50;
using Levels = std::array<std::array<std::int64_t, max_keys>, levels_count>;
using Counts = std::array<std::size_t, levels_count>;

std::int64_t prefix_of(std::int64_t key, std::size_t depth) noexcept {
    return depth == 0 ? 0 : key >> (universe_bits - depth);
}

int find_prefix(const Levels& prefixes, const Counts& counts, std::size_t depth,
                std::int64_t wanted) noexcept {
    std::size_t low = 0, high = counts[depth];
    while (low < high) {
        const auto middle = low + (high - low) / 2;
        if (prefixes[depth][middle] < wanted) low = middle + 1;
        else high = middle;
    }
    return low < counts[depth] && prefixes[depth][low] == wanted ? static_cast<int>(low) : -1;
}

std::int64_t predecessor(const Levels& prefixes, const Levels& maxima, const Counts& counts,
                         std::int64_t query) noexcept {
    std::size_t low = 0, high = levels_count;
    while (high - low > 1) {
        const auto middle = low + (high - low) / 2;
        if (find_prefix(prefixes, counts, middle, prefix_of(query, middle)) >= 0) low = middle;
        else high = middle;
    }
    if (low == universe_bits) return query;
    for (std::size_t depth = low + 1; depth > 0; --depth) {
        const auto query_prefix = query >> (universe_bits - depth);
        if ((query_prefix & 1) != 0) {
            const int sibling = find_prefix(prefixes, counts, depth, query_prefix - 1);
            if (sibling >= 0) return maxima[depth][static_cast<std::size_t>(sibling)];
        }
    }
    return -1;
}
}

extern "C" std::int64_t x_fast_trie_static_predecessor(const std::int64_t* input,
                                                         std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_keys) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_queries)) return -1;
    const auto n = static_cast<std::size_t>(input[0]), q = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + q || length > max_input) return -1;
    std::array<std::int64_t, max_keys> keys{};
    std::array<std::int64_t, max_queries> queries{};
    for (std::size_t i = 0; i < n; ++i) {
        keys[i] = input[2 + i];
        if (keys[i] < 0 || keys[i] > 65535) return -1;
    }
    std::sort(keys.begin(), keys.begin() + static_cast<std::ptrdiff_t>(n));
    for (std::size_t i = 1; i < n; ++i) if (keys[i] == keys[i - 1]) return -1;
    for (std::size_t i = 0; i < q; ++i) {
        queries[i] = input[2 + n + i];
        if (queries[i] < 0 || queries[i] > 65535) return -1;
    }
    if (n == 0 || q == 0) return 0;

    Levels prefixes{}, maxima{};
    Counts counts{};
    for (std::size_t depth = 0; depth < levels_count; ++depth) {
        for (std::size_t i = 0; i < n; ++i) {
            const auto value = prefix_of(keys[i], depth);
            if (counts[depth] == 0 || prefixes[depth][counts[depth] - 1] != value) {
                prefixes[depth][counts[depth]] = value;
                maxima[depth][counts[depth]] = keys[i];
                ++counts[depth];
            } else maxima[depth][counts[depth] - 1] = keys[i];
        }
    }
    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < q; ++i)
        checksum += static_cast<std::int64_t>(i + 1) * (predecessor(prefixes, maxima, counts, queries[i]) + 1);
    return checksum;
}
