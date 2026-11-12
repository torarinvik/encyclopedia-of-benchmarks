#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_q = 256;
constexpr std::int64_t modulus = 998'244'353;

std::int64_t normalize(std::int64_t value) noexcept {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

std::size_t find_root(std::size_t *parent, std::int64_t *difference,
                      std::size_t item) noexcept {
    if (parent[item] != item) {
        const auto old_parent = parent[item];
        const auto root = find_root(parent, difference, old_parent);
        difference[item] = normalize(difference[item] + difference[old_parent]);
        parent[item] = root;
    }
    return parent[item];
}

void store_i64_le(std::uint8_t *output, std::size_t offset,
                  std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t unionfind_with_potential(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 6 || length > 2 + 4 * max_q) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    if (length != 2 + 4 * q) return -1;

    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto position = 2 + 4 * operation;
        const auto kind = input[position], u = input[position + 1];
        const auto v = input[position + 2], x = input[position + 3];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value) return -1;
        if (kind == 0) {
            if (x < 0 || x >= modulus) return -1;
        } else if (kind == 1) {
            if (x != 0) return -1;
        } else {
            return -1;
        }
    }
    const auto required = 8 * q;
    if (output == nullptr || capacity < required) return -2;

    std::size_t parent[max_n], set_size[max_n];
    std::int64_t difference[max_n];
    for (std::size_t item = 0; item < n; ++item) {
        parent[item] = item;
        set_size[item] = 1;
        difference[item] = 0;
    }
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto position = 2 + 4 * operation;
        const auto kind = input[position];
        const auto u = static_cast<std::size_t>(input[position + 1]);
        const auto v = static_cast<std::size_t>(input[position + 2]);
        const auto x = input[position + 3];
        const auto root_u = find_root(parent, difference, u);
        const auto root_v = find_root(parent, difference, v);
        std::int64_t answer;
        if (kind == 1) {
            answer = root_u == root_v ? normalize(difference[u] - difference[v]) : -1;
        } else if (root_u == root_v) {
            answer = normalize(difference[u] - difference[v]) == x;
        } else if (set_size[root_u] < set_size[root_v]) {
            parent[root_u] = root_v;
            difference[root_u] = normalize(x - difference[u] + difference[v]);
            set_size[root_v] += set_size[root_u];
            answer = 1;
        } else {
            parent[root_v] = root_u;
            difference[root_v] = normalize(difference[u] - difference[v] - x);
            set_size[root_u] += set_size[root_v];
            answer = 1;
        }
        store_i64_le(output, 8 * operation, answer);
    }
    return static_cast<std::int64_t>(required);
}
