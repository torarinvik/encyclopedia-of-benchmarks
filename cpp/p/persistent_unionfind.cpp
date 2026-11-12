#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_q = 64;
constexpr std::size_t max_input_values = 2 + 4 * max_q;

std::size_t find_root(const std::array<std::size_t, max_n> &parent,
                      std::size_t item) noexcept {
    while (parent[item] != item) item = parent[item];
    return item;
}

void visit_version(std::size_t node,
    const std::array<std::int64_t, max_q> &kind,
    const std::array<std::int64_t, max_q> &u,
    const std::array<std::int64_t, max_q> &v,
    const std::array<std::int64_t, max_q + 1> &first_child,
    const std::array<std::int64_t, max_q> &next_sibling,
    std::array<std::size_t, max_n> &parent,
    std::array<std::size_t, max_n> &set_size,
    std::array<std::int64_t, max_q + 1> &answer,
    std::array<std::int64_t, max_q> &history_child,
    std::array<std::int64_t, max_q> &history_root,
    std::array<std::int64_t, max_q> &history_size,
    std::size_t &history_count) {
    const std::size_t saved_history = history_count;
    if (node != 0) {
        const std::size_t operation = node - 1;
        if (kind[operation] == 0) {
            auto root_u = find_root(parent, static_cast<std::size_t>(u[operation]));
            auto root_v = find_root(parent, static_cast<std::size_t>(v[operation]));
            if (root_u == root_v) {
                history_child[history_count] = -1;
                history_root[history_count] = -1;
                history_size[history_count] = 0;
            } else {
                if (set_size[root_u] > set_size[root_v]) {
                    const auto temporary = root_u;
                    root_u = root_v;
                    root_v = temporary;
                }
                history_child[history_count] = static_cast<std::int64_t>(root_u);
                history_root[history_count] = static_cast<std::int64_t>(root_v);
                history_size[history_count] = static_cast<std::int64_t>(set_size[root_v]);
                parent[root_u] = root_v;
                set_size[root_v] += set_size[root_u];
            }
            ++history_count;
        } else {
            answer[node] = find_root(parent, static_cast<std::size_t>(u[operation])) ==
                           find_root(parent, static_cast<std::size_t>(v[operation]));
        }
    }
    for (auto child = first_child[node]; child >= 0;
         child = next_sibling[static_cast<std::size_t>(child) - 1]) {
        visit_version(static_cast<std::size_t>(child), kind, u, v, first_child,
            next_sibling, parent, set_size, answer, history_child, history_root,
            history_size, history_count);
    }
    while (history_count > saved_history) {
        --history_count;
        const auto child = history_child[history_count];
        if (child >= 0) {
            const auto root = static_cast<std::size_t>(history_root[history_count]);
            parent[static_cast<std::size_t>(child)] = static_cast<std::size_t>(child);
            set_size[root] = static_cast<std::size_t>(history_size[history_count]);
        }
    }
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t persistent_unionfind(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 6 || length > max_input_values) return -1;
    const auto n_value = input[0];
    const auto q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    if (length != 2 + 4 * q) return -1;

    std::array<std::int64_t, max_q> kind{}, u{}, v{};
    std::array<std::int64_t, max_q + 1> first_child{}, answer{};
    std::array<std::int64_t, max_q> next_sibling{};
    first_child.fill(-1);
    std::size_t query_count = 0;
    for (std::size_t operation = 0; operation < q; ++operation) {
        const auto offset = 2 + 4 * operation;
        kind[operation] = input[offset];
        const auto version = input[offset + 1];
        u[operation] = input[offset + 2];
        v[operation] = input[offset + 3];
        if ((kind[operation] != 0 && kind[operation] != 1) ||
            version < -1 || version >= static_cast<std::int64_t>(operation) ||
            u[operation] < 0 || u[operation] >= n_value ||
            v[operation] < 0 || v[operation] >= n_value) return -1;
        if (version >= 0 && kind[static_cast<std::size_t>(version)] != 0) return -1;
        if (kind[operation] == 1) ++query_count;
        const auto parent_node = static_cast<std::size_t>(version + 1);
        next_sibling[operation] = first_child[parent_node];
        first_child[parent_node] = static_cast<std::int64_t>(operation + 1);
    }

    const auto required = 8 * query_count;
    if (output == nullptr || capacity < required) return -2;
    std::array<std::size_t, max_n> parent{}, set_size{};
    for (std::size_t item = 0; item < n; ++item) {
        parent[item] = item;
        set_size[item] = 1;
    }
    std::array<std::int64_t, max_q> history_child{}, history_root{}, history_size{};
    std::size_t history_count = 0;
    visit_version(0, kind, u, v, first_child, next_sibling, parent, set_size,
                  answer, history_child, history_root, history_size, history_count);
    std::size_t written = 0;
    for (std::size_t operation = 0; operation < q; ++operation) {
        if (kind[operation] == 1) {
            store_i64_le(output, written, answer[operation + 1]);
            written += 8;
        }
    }
    return static_cast<std::int64_t>(written);
}
