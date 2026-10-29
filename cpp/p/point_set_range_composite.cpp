#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 16;
constexpr std::size_t max_operations = 32;
constexpr std::size_t max_input_length = 162;
constexpr std::size_t tree_capacity = 64;

struct AffineMap {
    std::int64_t a;
    std::int64_t b;
};

constexpr AffineMap identity_map{1, 0};

// Apply left first and right second, producing right composed with left.
AffineMap compose(AffineMap left, AffineMap right)
{
    return {(right.a * left.a) % modulus,
            (right.a * left.b + right.b) % modulus};
}
} // namespace

extern "C" std::int64_t point_set_range_composite(const std::int64_t* values,
                                                    std::size_t length)
{
    if (values == nullptr || length < 2 || length > max_input_length) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(max_n) ||
        values[1] < 0 || values[1] > static_cast<std::int64_t>(max_operations)) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    const auto q = static_cast<std::size_t>(values[1]);
    if (length != 2 + 2 * n + 4 * q) return -1;

    for (std::size_t i = 0; i < n; ++i) {
        const auto a = values[2 + 2 * i];
        const auto b = values[3 + 2 * i];
        if (a < 0 || a >= modulus || b < 0 || b >= modulus) return -1;
    }

    std::size_t base = 1;
    while (base < n) base *= 2;
    std::array<AffineMap, tree_capacity> tree;
    tree.fill(identity_map);
    for (std::size_t i = 0; i < n; ++i) {
        tree[base + i] = {values[2 + 2 * i], values[3 + 2 * i]};
    }
    for (std::size_t node = base; node > 1; --node) {
        const auto parent = node - 1;
        tree[parent] = compose(tree[2 * parent], tree[2 * parent + 1]);
    }

    std::int64_t checksum = 0;
    std::int64_t query_number = 0;
    std::size_t cursor = 2 + 2 * n;
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto opcode = values[cursor];
        const auto first = values[cursor + 1];
        const auto second = values[cursor + 2];
        const auto third = values[cursor + 3];
        cursor += 4;
        if (opcode == 0) {
            if (first < 0 || first >= values[0] || second < 0 || second >= modulus ||
                third < 0 || third >= modulus) return -1;
            auto node = base + static_cast<std::size_t>(first);
            tree[node] = {second, third};
            while (node > 1) {
                node /= 2;
                tree[node] = compose(tree[2 * node], tree[2 * node + 1]);
            }
        } else if (opcode == 1) {
            if (first < 0 || first > second || second > values[0] ||
                third < 0 || third >= modulus) return -1;
            auto left_index = base + static_cast<std::size_t>(first);
            auto right_index = base + static_cast<std::size_t>(second);
            auto left = identity_map;
            auto right = identity_map;
            while (left_index < right_index) {
                if (left_index & 1U) left = compose(left, tree[left_index++]);
                if (right_index & 1U) right = compose(tree[--right_index], right);
                left_index /= 2;
                right_index /= 2;
            }
            const auto range = compose(left, right);
            const auto answer = (range.a * third + range.b) % modulus;
            ++query_number;
            checksum = (checksum + query_number * answer) % modulus;
        } else {
            return -1;
        }
    }
    return cursor == length ? checksum : -1;
}
