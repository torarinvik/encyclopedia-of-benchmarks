#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 64;
constexpr std::size_t MAX_OPERATIONS = 64;
constexpr std::size_t MAX_INPUT_LENGTH = 259;
constexpr std::size_t MAX_TREE_LENGTH = 128;
constexpr std::int64_t VALUE_MIN = -1'000'000;
constexpr std::int64_t VALUE_MAX = 1'000'000;
constexpr std::uint64_t FNV_OFFSET = 14695981039346656037ULL;
constexpr std::uint64_t FNV_PRIME = 1099511628211ULL;

std::int32_t query_sum(const std::int32_t *tree, std::size_t node,
                       std::size_t segment_left, std::size_t segment_right,
                       std::size_t query_left, std::size_t query_right)
{
    if (query_left <= segment_left && segment_right <= query_right) return tree[node];
    if (query_right < segment_left || segment_right < query_left) return 0;
    const std::size_t middle = segment_left + (segment_right - segment_left) / 2;
    return query_sum(tree, node * 2, segment_left, middle, query_left, query_right)
         + query_sum(tree, node * 2 + 1, middle + 1, segment_right, query_left, query_right);
}

std::uint64_t hash_i64_word(std::uint64_t hash, std::int64_t word)
{
    std::uint64_t bits = static_cast<std::uint64_t>(word);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        hash ^= bits & UINT64_C(255);
        hash *= FNV_PRIME;
        bits >>= 8;
    }
    return hash;
}
}

extern "C" std::int64_t segment_tree_update_benchmark(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length < n + 2) return -1;
    if (input[n + 1] < 1 || input[n + 1] > static_cast<std::int64_t>(MAX_OPERATIONS)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(input[n + 1]);
    if (length != n + 2 + 3 * operation_count) return -1;

    for (std::size_t index = 0; index < n; ++index)
        if (input[index + 1] < VALUE_MIN || input[index + 1] > VALUE_MAX) return -1;
    const std::size_t operations_start = n + 2;
    std::size_t query_count = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t offset = operations_start + 3 * operation;
        const std::int64_t type = input[offset], first = input[offset + 1], second = input[offset + 2];
        if (type == 0) {
            if (first < 0 || first > second || second >= static_cast<std::int64_t>(n)) return -1;
            ++query_count;
        } else if (type == 1) {
            if (first < 0 || first >= static_cast<std::int64_t>(n) || second < VALUE_MIN || second > VALUE_MAX) return -1;
        } else {
            return -1;
        }
    }
    if (query_count == 0) return -1;

    std::size_t power = 1;
    while (power < n) power *= 2;
    std::int32_t tree[MAX_TREE_LENGTH] = {};
    for (std::size_t index = 0; index < n; ++index) tree[power + index] = static_cast<std::int32_t>(input[index + 1]);
    for (std::size_t node = power - 1; node > 0; --node)
        tree[node] = tree[node * 2] + tree[node * 2 + 1];

    std::uint64_t hash = hash_i64_word(FNV_OFFSET, static_cast<std::int64_t>(query_count));
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t offset = operations_start + 3 * operation;
        const std::int64_t type = input[offset], first = input[offset + 1], second = input[offset + 2];
        if (type == 0) {
            const std::int32_t sum = query_sum(tree, 1, 1, power,
                                               static_cast<std::size_t>(first) + 1,
                                               static_cast<std::size_t>(second) + 1);
            hash = hash_i64_word(hash, sum);
        } else {
            std::size_t node = power + static_cast<std::size_t>(first);
            tree[node] = static_cast<std::int32_t>(second);
            while (node > 1) {
                node /= 2;
                tree[node] = tree[node * 2] + tree[node * 2 + 1];
            }
        }
    }
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
