// Online rectangle counts using Fenwick trees over x-blocks and y-values.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 24;
constexpr std::size_t kMaxQ = 32;
constexpr std::size_t kMaxParseableLength = 187;
constexpr std::size_t kTreeStride = 25;

void inner_add(std::array<std::int64_t, 150>& trees, std::size_t n,
               std::size_t node, std::int64_t y, std::int64_t delta) noexcept {
    auto index = static_cast<std::size_t>(y) + 1;
    while (index <= n) {
        trees[node * kTreeStride + index] += delta;
        index += index & (~index + 1);
    }
}

std::int64_t inner_prefix(const std::array<std::int64_t, 150>& trees,
                          std::size_t node, std::int64_t y_limit) noexcept {
    std::int64_t total = 0;
    auto index = static_cast<std::size_t>(y_limit);
    while (index > 0) {
        total += trees[node * kTreeStride + index];
        index -= index & (~index + 1);
    }
    return total;
}

std::int64_t prefix_count(const std::array<std::int64_t, 24>& ys,
                          const std::array<std::int64_t, 150>& trees,
                          std::size_t block_size,
                          std::size_t x_limit, std::int64_t y_limit) noexcept {
    const auto full_blocks = x_limit / block_size;
    auto node = full_blocks;
    std::int64_t total = 0;
    while (node > 0) {
        total += inner_prefix(trees, node, y_limit);
        node -= node & (~node + 1);
    }
    for (auto x = full_blocks * block_size; x < x_limit; ++x)
        if (ys[x] < y_limit) ++total;
    return total;
}
} // namespace

extern "C" std::int64_t fenwick_tree_in_block_array_rectangle_count(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxParseableLength) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxN)
            || q_value < 1 || q_value > static_cast<std::int64_t>(kMaxQ)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    const auto operations_at = 2 + n;
    if (length != operations_at + 5 * q) return -1;

    std::array<std::int64_t, 24> ys{};
    for (std::size_t x = 0; x < n; ++x) {
        ys[x] = input[2 + x];
        if (ys[x] < 0 || ys[x] >= n_value) return -1;
    }
    for (std::size_t j = 0; j < q; ++j) {
        const auto at = operations_at + 5 * j;
        const auto kind = input[at];
        if (kind == 0) {
            if (input[at + 1] < 0 || input[at + 1] >= n_value
                    || input[at + 2] < 0 || input[at + 2] >= n_value
                    || input[at + 3] != 0 || input[at + 4] != 0) return -1;
        } else if (kind == 1) {
            if (input[at + 1] < 0 || input[at + 1] > input[at + 2]
                    || input[at + 2] > n_value
                    || input[at + 3] < 0 || input[at + 3] > input[at + 4]
                    || input[at + 4] > n_value) return -1;
        } else {
            return -1;
        }
    }

    std::size_t block_size = 1;
    while (block_size * block_size < n) ++block_size;
    const auto block_count = (n + block_size - 1) / block_size;
    std::array<std::int64_t, 150> trees{};
    for (std::size_t x = 0; x < n; ++x) {
        auto node = x / block_size + 1;
        while (node <= block_count) {
            inner_add(trees, n, node, ys[x], 1);
            node += node & (~node + 1);
        }
    }

    std::int64_t checksum = 0, query_ordinal = 0;
    for (std::size_t j = 0; j < q; ++j) {
        const auto at = operations_at + 5 * j;
        if (input[at] == 0) {
            const auto x = static_cast<std::size_t>(input[at + 1]);
            const auto new_y = input[at + 2];
            auto node = x / block_size + 1;
            while (node <= block_count) {
                inner_add(trees, n, node, ys[x], -1);
                inner_add(trees, n, node, new_y, 1);
                node += node & (~node + 1);
            }
            ys[x] = new_y;
        } else {
            const auto x_left = static_cast<std::size_t>(input[at + 1]);
            const auto x_right = static_cast<std::size_t>(input[at + 2]);
            const auto y_low = input[at + 3], y_high = input[at + 4];
            const auto count = prefix_count(ys, trees, block_size, x_right, y_high)
                - prefix_count(ys, trees, block_size, x_left, y_high)
                - prefix_count(ys, trees, block_size, x_right, y_low)
                + prefix_count(ys, trees, block_size, x_left, y_low);
            ++query_ordinal;
            checksum += query_ordinal * count;
        }
    }
    return checksum;
}
