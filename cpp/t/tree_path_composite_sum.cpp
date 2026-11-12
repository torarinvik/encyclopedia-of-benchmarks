#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_n = 32;
constexpr std::size_t max_input_values = 5 * max_n - 3;
constexpr std::int64_t mod = 998'244'353;

std::size_t find_root(std::array<std::size_t, max_n> &parent, std::size_t item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

void store_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tree_path_composite_sum(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_values) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + n + 4 * (n - 1)) return -1;

    std::array<std::int64_t, max_n> value{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        value[vertex] = input[1 + vertex];
        if (value[vertex] < 0 || value[vertex] >= mod) return -1;
    }
    std::array<std::array<bool, max_n>, max_n> adjacent{};
    std::array<std::array<std::int64_t, max_n>, max_n> multiplier{}, addend{};
    std::array<std::size_t, max_n> dsu_parent{}, dsu_size{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    auto offset = 1 + n;
    for (std::size_t edge = 0; edge + 1 < n; ++edge) {
        const auto u_value = input[offset++], v_value = input[offset++];
        const auto b = input[offset++], c = input[offset++];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            u_value == v_value || b < 1 || b >= mod || c < 0 || c >= mod) return -1;
        const auto u = static_cast<std::size_t>(u_value);
        const auto v = static_cast<std::size_t>(v_value);
        auto root_u = find_root(dsu_parent, u), root_v = find_root(dsu_parent, v);
        if (root_u == root_v) return -1;
        if (dsu_size[root_u] < dsu_size[root_v]) std::swap(root_u, root_v);
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        adjacent[u][v] = adjacent[v][u] = true;
        multiplier[u][v] = multiplier[v][u] = b;
        addend[u][v] = addend[v][u] = c;
    }

    std::array<std::size_t, max_n> order{}, stack{};
    std::array<std::int64_t, max_n> parent{};
    parent.fill(-2);
    parent[0] = -1;
    std::size_t top = 1, order_count = 0;
    stack[0] = 0;
    while (top > 0) {
        const auto u = stack[--top];
        order[order_count++] = u;
        for (std::size_t v = 0; v < n; ++v) {
            if (adjacent[u][v] && static_cast<std::int64_t>(v) != parent[u]) {
                parent[v] = static_cast<std::int64_t>(u);
                stack[top++] = v;
            }
        }
    }

    std::array<std::int64_t, max_n> down_sum{}, up_sum{}, answer{};
    std::array<std::size_t, max_n> down_count{}, up_count{};
    for (std::size_t position = order_count; position > 0; --position) {
        const auto u = order[position - 1];
        down_sum[u] = value[u];
        down_count[u] = 1;
        for (std::size_t v = 0; v < n; ++v) {
            if (adjacent[u][v] && parent[v] == static_cast<std::int64_t>(u)) {
                const auto contribution = (multiplier[u][v] * down_sum[v]
                    + addend[u][v] * static_cast<std::int64_t>(down_count[v])) % mod;
                down_sum[u] = (down_sum[u] + contribution) % mod;
                down_count[u] += down_count[v];
            }
        }
    }
    for (std::size_t position = 0; position < order_count; ++position) {
        const auto u = order[position];
        auto total_sum = value[u];
        std::size_t total_count = 1;
        if (parent[u] >= 0) {
            total_sum = (total_sum + up_sum[u]) % mod;
            total_count += up_count[u];
        }
        for (std::size_t v = 0; v < n; ++v) {
            if (adjacent[u][v] && parent[v] == static_cast<std::int64_t>(u)) {
                total_sum = (total_sum + multiplier[u][v] * down_sum[v]
                    + addend[u][v] * static_cast<std::int64_t>(down_count[v])) % mod;
                total_count += down_count[v];
            }
        }
        answer[u] = total_sum;
        for (std::size_t v = 0; v < n; ++v) {
            if (adjacent[u][v] && parent[v] == static_cast<std::int64_t>(u)) {
                const auto contribution = (multiplier[u][v] * down_sum[v]
                    + addend[u][v] * static_cast<std::int64_t>(down_count[v])) % mod;
                const auto outside_sum = (total_sum - contribution + mod) % mod;
                const auto outside_count = total_count - down_count[v];
                up_sum[v] = (multiplier[u][v] * outside_sum
                    + addend[u][v] * static_cast<std::int64_t>(outside_count)) % mod;
                up_count[v] = outside_count;
            }
        }
    }

    const auto required = 8 * n;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        store_le(output, 8 * vertex, answer[vertex]);
    return static_cast<std::int64_t>(required);
}
