#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_q = 64;
constexpr std::size_t max_levels = 6;
constexpr std::int64_t modulus = 998'244'353;

std::int64_t normalize(std::int64_t value) noexcept {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

using Layers = std::array<std::array<std::size_t, max_n>, max_levels>;

std::size_t find_root(Layers &parent, std::size_t level, std::size_t item) noexcept {
    if (parent[level][item] != item)
        parent[level][item] = find_root(parent, level, parent[level][item]);
    return parent[level][item];
}

void merge_inner(std::size_t level, std::size_t left, std::size_t right,
    Layers &parent, Layers &set_size, std::array<std::int64_t, max_n> &weight,
    std::int64_t &pair_sum) noexcept {
    auto root_left = find_root(parent, level, left);
    auto root_right = find_root(parent, level, right);
    if (root_left == root_right) return;
    if (set_size[level][root_left] < set_size[level][root_right]) {
        const auto temporary = root_left;
        root_left = root_right;
        root_right = temporary;
    }
    parent[level][root_right] = root_left;
    set_size[level][root_left] += set_size[level][root_right];
    if (level == 0) {
        pair_sum = normalize(pair_sum + weight[root_left] * weight[root_right]);
        weight[root_left] = normalize(weight[root_left] + weight[root_right]);
        return;
    }
    const auto half = std::size_t{1} << (level - 1);
    merge_inner(level - 1, left, right, parent, set_size, weight, pair_sum);
    merge_inner(level - 1, left + half, right + half, parent, set_size, weight, pair_sum);
}

std::size_t floor_log2(std::size_t value) noexcept {
    std::size_t level = 0;
    while (value > 1) { value >>= 1; ++level; }
    return level;
}

void merge_ranges(std::size_t length, std::size_t left, std::size_t right,
    Layers &parent, Layers &set_size, std::array<std::int64_t, max_n> &weight,
    std::int64_t &pair_sum) noexcept {
    if (length == 0) return;
    const auto level = floor_log2(length - 1);
    const auto block = std::size_t{1} << level;
    merge_inner(level, left, right, parent, set_size, weight, pair_sum);
    merge_inner(level, left + length - block, right + length - block,
                parent, set_size, weight, pair_sum);
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t range_parallel_unionfind(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 6 || length > 2 + max_n + 3 * max_q) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 2 + n + 3 * q) return -1;
    for (std::size_t item = 0; item < n; ++item)
        if (input[2 + item] < 0 || input[2 + item] >= modulus) return -1;
    const auto operations_at = 2 + n;
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto position = operations_at + 3 * operation;
        const auto span = input[position], left = input[position + 1], right = input[position + 2];
        if (span < 0 || span > n_value || left < 0 || right < 0 ||
            left > n_value - span || right > n_value - span) return -1;
    }
    const auto required = 8 * q;
    if (output == nullptr || capacity < required) return -2;

    Layers parent{}, set_size{};
    std::array<std::int64_t, max_n> weight{};
    for (std::size_t level = 0; level < max_levels; ++level) {
        const auto block = std::size_t{1} << level;
        if (block > n) break;
        const auto positions = n - block + 1;
        for (std::size_t start = 0; start < positions; ++start) {
            parent[level][start] = start;
            set_size[level][start] = 1;
        }
    }
    for (std::size_t item = 0; item < n; ++item) weight[item] = input[2 + item];
    std::int64_t pair_sum = 0;
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto position = operations_at + 3 * operation;
        merge_ranges(static_cast<std::size_t>(input[position]),
            static_cast<std::size_t>(input[position + 1]), static_cast<std::size_t>(input[position + 2]),
            parent, set_size, weight, pair_sum);
        store_i64_le(output, 8 * operation, pair_sum);
    }
    return static_cast<std::int64_t>(required);
}
