#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32;
constexpr std::size_t max_q = 32;
constexpr std::size_t max_output_bytes = 8 * max_q;

void tree_set(std::array<int, 128> &tree, std::size_t base,
              std::size_t value, int present) noexcept {
    auto node = base + value;
    tree[node] = present;
    while ((node >>= 1) > 0) tree[node] = tree[2 * node] + tree[2 * node + 1];
}

std::size_t find_mex(const std::array<int, 128> &tree, std::size_t base,
                     std::size_t domain_size) noexcept {
    std::size_t node = 1, start = 0, span = base;
    while (span > 1) {
        const auto half = span / 2;
        const auto left_width = start >= domain_size ? 0 :
            (domain_size - start < half ? domain_size - start : half);
        if (static_cast<std::size_t>(tree[2 * node]) < left_width) {
            node *= 2;
            span = half;
        } else {
            node = 2 * node + 1;
            start += half;
            span = half;
        }
    }
    return start;
}

void write_i64_le(std::array<std::uint8_t, max_output_bytes> &out,
                  std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        out[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t dynamic_mex_updates(const std::int64_t *input,
                                             std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 99) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 0 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    if (length != 2 + n + 2 * q) return -1;

    std::array<std::int64_t, max_n> current{};
    std::array<std::size_t, max_q> update_indices{};
    std::array<std::int64_t, max_q> update_values{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[2 + i];
        if (value < -1000 || value > 1000) return -1;
        current[i] = value;
    }
    auto cursor = 2 + n;
    for (std::size_t i = 0; i < q; ++i) {
        const auto index = input[cursor++];
        const auto value = input[cursor++];
        if (index < 0 || index >= n_value || value < -1000 || value > 1000) return -1;
        update_indices[i] = static_cast<std::size_t>(index);
        update_values[i] = value;
    }
    const auto needed = 8 * q;
    if (needed > 0 && (output == nullptr || capacity < needed)) return -2;

    std::size_t base = 1;
    while (base < n + 1) base *= 2;
    const auto domain_size = n + 1;
    std::array<int, max_n + 1> frequencies{};
    std::array<int, 128> tree{};
    for (std::size_t i = 0; i < n; ++i)
        if (current[i] >= 0 && current[i] <= n_value) ++frequencies[static_cast<std::size_t>(current[i])];
    for (std::size_t value = 0; value < domain_size; ++value)
        tree[base + value] = frequencies[value] > 0 ? 1 : 0;
    for (auto node = base; node-- > 1;)
        tree[node] = tree[2 * node] + tree[2 * node + 1];

    std::array<std::uint8_t, max_output_bytes> staged{};
    for (std::size_t op = 0; op < q; ++op) {
        const auto index = update_indices[op];
        const auto old_value = current[index];
        const auto new_value = update_values[op];
        if (old_value != new_value) {
            if (old_value >= 0 && old_value <= n_value) {
                const auto old_index = static_cast<std::size_t>(old_value);
                if (--frequencies[old_index] == 0) tree_set(tree, base, old_index, 0);
            }
            if (new_value >= 0 && new_value <= n_value) {
                const auto new_index = static_cast<std::size_t>(new_value);
                if (frequencies[new_index] == 0) tree_set(tree, base, new_index, 1);
                ++frequencies[new_index];
            }
            current[index] = new_value;
        }
        write_i64_le(staged, 8 * op, static_cast<std::int64_t>(find_mex(tree, base, domain_size)));
    }
    for (std::size_t byte = 0; byte < needed; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(needed);
}
