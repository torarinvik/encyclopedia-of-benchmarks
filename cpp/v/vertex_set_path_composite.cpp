#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_q = 64;
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_input_values = 4 * max_n + 4 * max_q;

struct Affine { std::int64_t a, b; };
struct Aggregate { Affine forward, backward; };

Affine identity() noexcept { return {1, 0}; }
Affine compose(Affine after, Affine before) noexcept {
    return {(after.a * before.a) % modulus,
            (after.a * before.b + after.b) % modulus};
}
Aggregate identity_aggregate() noexcept {
    const auto id = identity();
    return {id, id};
}
Aggregate combine(Aggregate left, Aggregate right) noexcept {
    return {compose(right.forward, left.forward), compose(left.backward, right.backward)};
}

std::size_t find_root(std::array<std::size_t, max_n> &parent, std::size_t item) noexcept {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

void update_leaf(std::array<Aggregate, 2 * max_n> &tree, std::size_t base,
                 std::size_t position, Affine value) noexcept {
    auto node = base + position;
    tree[node] = {value, value};
    while (node > 1) {
        node >>= 1;
        tree[node] = combine(tree[node << 1], tree[(node << 1) | 1]);
    }
}

Aggregate range_query(const std::array<Aggregate, 2 * max_n> &tree,
                      std::size_t base, std::size_t left, std::size_t right) noexcept {
    auto prefix = identity_aggregate(), suffix = identity_aggregate();
    left += base;
    right += base;
    while (left < right) {
        if (left & 1U) prefix = combine(prefix, tree[left++]);
        if (right & 1U) suffix = combine(tree[--right], suffix);
        left >>= 1;
        right >>= 1;
    }
    return combine(prefix, suffix);
}

Affine path_composition(const std::array<Aggregate, 2 * max_n> &tree, std::size_t base,
    const std::array<std::size_t, max_n> &parent,
    const std::array<std::size_t, max_n> &depth,
    const std::array<std::size_t, max_n> &head,
    const std::array<std::size_t, max_n> &position,
    std::size_t from, std::size_t to) noexcept {
    auto left = identity(), right = identity();
    while (head[from] != head[to]) {
        if (depth[head[from]] >= depth[head[to]]) {
            const auto part = range_query(tree, base, position[head[from]], position[from] + 1);
            left = compose(part.backward, left);
            from = parent[head[from]];
        } else {
            const auto part = range_query(tree, base, position[head[to]], position[to] + 1);
            right = compose(right, part.forward);
            to = parent[head[to]];
        }
    }
    if (depth[from] >= depth[to]) {
        const auto part = range_query(tree, base, position[to], position[from] + 1);
        left = compose(part.backward, left);
    } else {
        const auto part = range_query(tree, base, position[from], position[to] + 1);
        right = compose(right, part.forward);
    }
    return compose(right, left);
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t vertex_set_path_composite(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 8 || length > max_input_values) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 4 * n + 4 * q) return -1;

    std::array<Affine, max_n> values{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        const auto a = input[2 + 2 * vertex], b = input[3 + 2 * vertex];
        if (a < 1 || a >= modulus || b < 0 || b >= modulus) return -1;
        values[vertex] = {a, b};
    }

    std::array<std::array<bool, max_n>, max_n> adjacent{};
    std::array<std::size_t, max_n> dsu_parent{}, dsu_size{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    const auto edge_start = 2 + 2 * n;
    for (std::size_t edge = 0; edge + 1 < n; ++edge) {
        const auto offset = edge_start + 2 * edge;
        const auto left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const auto left = static_cast<std::size_t>(left_value);
        const auto right = static_cast<std::size_t>(right_value);
        auto root_left = find_root(dsu_parent, left), root_right = find_root(dsu_parent, right);
        if (root_left == root_right) return -1;
        if (dsu_size[root_left] < dsu_size[root_right]) {
            const auto temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = adjacent[right][left] = true;
    }

    const auto operation_start = edge_start + 2 * (n - 1);
    for (std::size_t query = 0; query < q; ++query) {
        const auto offset = operation_start + 4 * query;
        const auto kind = input[offset], first = input[offset + 1];
        const auto second = input[offset + 2], third = input[offset + 3];
        if (kind == 0) {
            if (first < 0 || first >= n_value || second < 1 || second >= modulus ||
                third < 0 || third >= modulus) return -1;
        } else if (kind == 1) {
            if (first < 0 || first >= n_value || second < 0 || second >= n_value ||
                third < 0 || third >= modulus) return -1;
        } else return -1;
    }

    std::array<std::size_t, max_n> parent{}, depth{}, subtree{}, heavy{}, order{}, stack{};
    std::size_t order_count = 0, top = 0;
    parent[0] = 0;
    subtree[0] = 1;
    heavy[0] = max_n;
    stack[top++] = 0;
    order[order_count++] = 0;
    while (top > 0) {
        const auto vertex = stack[--top];
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (!adjacent[vertex][neighbor] || neighbor == parent[vertex]) continue;
            parent[neighbor] = vertex;
            depth[neighbor] = depth[vertex] + 1;
            subtree[neighbor] = 1;
            heavy[neighbor] = max_n;
            order[order_count++] = neighbor;
            stack[top++] = neighbor;
        }
    }
    for (std::size_t index = order_count; index > 1; --index) {
        const auto vertex = order[index - 1], p = parent[vertex];
        subtree[p] += subtree[vertex];
        if (heavy[p] == max_n || subtree[vertex] > subtree[heavy[p]] ||
            (subtree[vertex] == subtree[heavy[p]] && vertex < heavy[p])) heavy[p] = vertex;
    }

    std::array<std::size_t, max_n> head{}, position{}, chain_vertex{}, chain_head{};
    std::size_t chain_count = 0, timer = 0;
    chain_vertex[chain_count] = 0;
    chain_head[chain_count++] = 0;
    while (chain_count > 0) {
        --chain_count;
        auto vertex = chain_vertex[chain_count];
        const auto current_head = chain_head[chain_count];
        while (vertex != max_n) {
            head[vertex] = current_head;
            position[vertex] = timer++;
            for (std::size_t child = 0; child < n; ++child) {
                if (adjacent[vertex][child] && parent[child] == vertex && child != heavy[vertex]) {
                    chain_vertex[chain_count] = child;
                    chain_head[chain_count++] = child;
                }
            }
            vertex = heavy[vertex];
        }
    }

    std::size_t base = 1;
    while (base < n) base <<= 1;
    std::array<Aggregate, 2 * max_n> tree{};
    for (std::size_t node = 0; node < 2 * base; ++node) tree[node] = identity_aggregate();
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        update_leaf(tree, base, position[vertex], values[vertex]);

    std::array<std::int64_t, max_q> answers{};
    std::size_t answer_count = 0;
    for (std::size_t query = 0; query < q; ++query) {
        const auto offset = operation_start + 4 * query;
        const auto kind = input[offset];
        const auto first = static_cast<std::size_t>(input[offset + 1]);
        const auto second = input[offset + 2], third = input[offset + 3];
        if (kind == 0) {
            values[first] = {second, third};
            update_leaf(tree, base, position[first], values[first]);
        } else {
            const auto combined = path_composition(tree, base, parent, depth, head, position,
                first, static_cast<std::size_t>(second));
            answers[answer_count++] = (combined.a * third + combined.b) % modulus;
        }
    }

    const auto required = 8 * answer_count;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < answer_count; ++index)
        store_i64_le(output, 8 * index, answers[index]);
    return static_cast<std::int64_t>(required);
}
