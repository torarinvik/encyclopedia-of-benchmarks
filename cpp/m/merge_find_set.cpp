#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 256;
constexpr std::int64_t MAX_MERGES = 512;
constexpr std::size_t MAX_PARSEABLE_INPUT_LENGTH = 1028;
}

extern "C" std::int64_t merge_find_set(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N) ||
        input[1] < 0 || input[1] > MAX_MERGES) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t merge_count = static_cast<std::size_t>(input[1]);
    if (length != 2 * merge_count + 3) return -1;

    std::array<std::int64_t, MAX_N> parent{};
    std::array<std::int64_t, MAX_N> rank{};
    for (std::size_t element = 0; element < n; ++element) parent[element] = static_cast<std::int64_t>(element);
    for (std::size_t operation = 0; operation < merge_count; ++operation) {
        const std::size_t position = 2 + 2 * operation;
        const std::int64_t first = input[position], second = input[position + 1];
        if (first < 0 || second < 0 || first >= static_cast<std::int64_t>(n) ||
            second >= static_cast<std::int64_t>(n)) return -1;
        std::int64_t first_root = first, second_root = second;
        while (parent[static_cast<std::size_t>(first_root)] != first_root)
            first_root = parent[static_cast<std::size_t>(first_root)];
        while (parent[static_cast<std::size_t>(second_root)] != second_root)
            second_root = parent[static_cast<std::size_t>(second_root)];
        if (first_root == second_root) continue;
        const std::size_t x = static_cast<std::size_t>(first_root);
        const std::size_t y = static_cast<std::size_t>(second_root);
        if (rank[x] < rank[y]) {
            parent[x] = second_root;
        } else if (rank[x] > rank[y]) {
            parent[y] = first_root;
        } else {
            parent[x] = second_root;
            ++rank[y];
        }
    }

    std::int64_t query = input[length - 1];
    if (query < 0 || query >= static_cast<std::int64_t>(n)) return -1;
    while (parent[static_cast<std::size_t>(query)] != query)
        query = parent[static_cast<std::size_t>(query)];
    return query;
}
