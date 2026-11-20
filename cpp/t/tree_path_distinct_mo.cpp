#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32;
constexpr std::size_t max_q = 32;
constexpr std::size_t max_input = 3 * max_n + 2 * max_q;

struct Query {
    std::size_t left{}, right{}, id{}, block{}, right_key{};
};

std::size_t find_root(std::array<std::size_t, max_n> &parent, std::size_t item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

void make_euler(std::size_t vertex, std::size_t previous, std::size_t n,
                const std::array<std::array<bool, max_n>, max_n> &adjacent,
                std::array<std::size_t, max_n> &parent,
                std::array<std::size_t, max_n> &depth,
                std::array<std::size_t, max_n> &entry,
                std::array<std::size_t, max_n> &leave,
                std::array<std::size_t, 2 * max_n> &euler,
                std::size_t &clock) {
    parent[vertex] = previous;
    entry[vertex] = clock++;
    euler[entry[vertex]] = vertex;
    for (std::size_t next = 0; next < n; ++next) {
        if (adjacent[vertex][next] && next != previous) {
            depth[next] = depth[vertex] + 1;
            make_euler(next, vertex, n, adjacent, parent, depth,
                       entry, leave, euler, clock);
        }
    }
    leave[vertex] = clock++;
    euler[leave[vertex]] = vertex;
}

std::size_t lca(std::size_t a, std::size_t b,
                const std::array<std::size_t, max_n> &parent,
                const std::array<std::size_t, max_n> &depth) {
    while (depth[a] > depth[b]) a = parent[a];
    while (depth[b] > depth[a]) b = parent[b];
    while (a != b) { a = parent[a]; b = parent[b]; }
    return a;
}

void toggle(std::size_t vertex, const std::array<std::size_t, max_n> &color_id,
            std::array<std::size_t, max_n> &counts,
            std::array<bool, max_n> &active, std::size_t &distinct) {
    const auto color = color_id[vertex];
    if (active[vertex]) {
        active[vertex] = false;
        if (--counts[color] == 0) --distinct;
    } else {
        active[vertex] = true;
        if (counts[color]++ == 0) ++distinct;
    }
}

void store_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tree_path_distinct_mo(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input + 1) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 0 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    if (length != 3 * n + 2 * q) return -1;

    std::array<std::int64_t, max_n> colors{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) colors[vertex] = input[2 + vertex];
    std::array<std::array<bool, max_n>, max_n> adjacent{};
    std::array<std::size_t, max_n> dsu_parent{}, dsu_size{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    auto offset = 2 + n;
    for (std::size_t edge = 0; edge + 1 < n; ++edge) {
        const auto raw_u = input[offset++], raw_v = input[offset++];
        if (raw_u < 0 || raw_u >= n_value || raw_v < 0 || raw_v >= n_value || raw_u == raw_v)
            return -1;
        const auto u = static_cast<std::size_t>(raw_u), v = static_cast<std::size_t>(raw_v);
        auto root_u = find_root(dsu_parent, u), root_v = find_root(dsu_parent, v);
        if (root_u == root_v) return -1;
        if (dsu_size[root_u] < dsu_size[root_v]) std::swap(root_u, root_v);
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        adjacent[u][v] = adjacent[v][u] = true;
    }

    std::array<std::size_t, max_q> query_u{}, query_v{};
    for (std::size_t id = 0; id < q; ++id) {
        const auto u = input[offset++], v = input[offset++];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value) return -1;
        query_u[id] = static_cast<std::size_t>(u);
        query_v[id] = static_cast<std::size_t>(v);
    }

    std::array<std::size_t, max_n> color_id{}, first_color{};
    std::size_t color_count = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        std::size_t rank = 0;
        while (rank < color_count && colors[first_color[rank]] != colors[vertex]) ++rank;
        if (rank == color_count) first_color[color_count++] = vertex;
        color_id[vertex] = rank;
    }

    std::array<std::size_t, max_n> parent{}, depth{}, entry{}, leave{};
    std::array<std::size_t, 2 * max_n> euler{};
    std::size_t clock = 0;
    make_euler(0, n, n, adjacent, parent, depth, entry, leave, euler, clock);
    std::array<Query, max_q> queries{};
    std::size_t block_size = 1;
    while ((block_size + 1) * (block_size + 1) <= 2 * n) ++block_size;
    for (std::size_t id = 0; id < q; ++id) {
        auto u = query_u[id], v = query_v[id];
        if (entry[u] > entry[v]) std::swap(u, v);
        const auto ancestor = lca(u, v, parent, depth);
        const auto left = ancestor == u ? entry[u] : leave[u];
        const auto right = entry[v];
        const auto block = left / block_size;
        queries[id] = {left, right, id, block,
            block % 2 == 0 ? right : 2 * n - 1 - right};
    }
    std::sort(queries.begin(), queries.begin() + static_cast<std::ptrdiff_t>(q),
        [](const Query &a, const Query &b) {
            if (a.block != b.block) return a.block < b.block;
            if (a.right_key != b.right_key) return a.right_key < b.right_key;
            return a.id < b.id;
        });

    std::array<std::size_t, max_n> counts{}, answers{};
    std::array<bool, max_n> active{};
    std::size_t distinct = 0;
    std::ptrdiff_t left = 0, right = -1;
    for (std::size_t i = 0; i < q; ++i) {
        const auto query = queries[i];
        while (left > static_cast<std::ptrdiff_t>(query.left)) {
            --left;
            toggle(euler[static_cast<std::size_t>(left)], color_id, counts, active, distinct);
        }
        while (right < static_cast<std::ptrdiff_t>(query.right)) {
            ++right;
            toggle(euler[static_cast<std::size_t>(right)], color_id, counts, active, distinct);
        }
        while (left < static_cast<std::ptrdiff_t>(query.left)) {
            toggle(euler[static_cast<std::size_t>(left)], color_id, counts, active, distinct);
            ++left;
        }
        while (right > static_cast<std::ptrdiff_t>(query.right)) {
            toggle(euler[static_cast<std::size_t>(right)], color_id, counts, active, distinct);
            --right;
        }
        const auto u = query_u[query.id], v = query_v[query.id];
        const auto ancestor = lca(u, v, parent, depth);
        if (ancestor != u && ancestor != v) {
            toggle(ancestor, color_id, counts, active, distinct);
            answers[query.id] = distinct;
            toggle(ancestor, color_id, counts, active, distinct);
        } else {
            answers[query.id] = distinct;
        }
    }

    const auto required = 8 * q;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t id = 0; id < q; ++id)
        store_le(output, 8 * id, static_cast<std::int64_t>(answers[id]));
    return static_cast<std::int64_t>(required);
}
