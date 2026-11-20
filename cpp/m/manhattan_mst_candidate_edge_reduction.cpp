#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 31;
constexpr int max_candidates = 4 * max_n;

struct Point { int x = 0, y = 0, id = 0; };
struct Edge { int u = 0, v = 0, weight = 0; };

bool point_sum_less(const Point &left, const Point &right) noexcept {
    const int left_sum = left.x + left.y, right_sum = right.x + right.y;
    if (left_sum != right_sum) return left_sum < right_sum;
    if (left.x != right.x) return left.x < right.x;
    if (left.y != right.y) return left.y < right.y;
    return left.id < right.id;
}

bool point_x_less(const Point &left, const Point &right) noexcept {
    if (left.x != right.x) return left.x < right.x;
    if (left.y != right.y) return left.y < right.y;
    return left.id < right.id;
}

void fenwick_add(std::array<int, max_n + 1> &tree, int n, int index, int delta) noexcept {
    for (int at = index + 1; at <= n; at += at & -at) tree[static_cast<std::size_t>(at)] += delta;
}

int fenwick_prefix(const std::array<int, max_n + 1> &tree, int count) noexcept {
    int result = 0;
    for (int at = count; at > 0; at -= at & -at) result += tree[static_cast<std::size_t>(at)];
    return result;
}

int fenwick_kth(const std::array<int, max_n + 1> &tree, int n, int rank) noexcept {
    int index = 0, accumulated = 0, step = 1;
    while (step * 2 <= n) step *= 2;
    for (; step > 0; step /= 2) {
        const int next = index + step;
        if (next <= n && accumulated + tree[static_cast<std::size_t>(next)] < rank) {
            index = next;
            accumulated += tree[static_cast<std::size_t>(next)];
        }
    }
    return index;
}

void append_edge(std::array<Edge, max_candidates> &edges, int &edge_count,
                 const std::array<Point, max_n> &original, int u, int v) noexcept {
    const Point &left = original[static_cast<std::size_t>(u)];
    const Point &right = original[static_cast<std::size_t>(v)];
    const int dx = left.x >= right.x ? left.x - right.x : right.x - left.x;
    const int dy = left.y >= right.y ? left.y - right.y : right.y - left.y;
    edges[static_cast<std::size_t>(edge_count++)] = {u, v, dx + dy};
}

bool edge_less(const Edge &left, const Edge &right) noexcept {
    if (left.weight != right.weight) return left.weight < right.weight;
    const int left_u = left.u < left.v ? left.u : left.v;
    const int left_v = left.u < left.v ? left.v : left.u;
    const int right_u = right.u < right.v ? right.u : right.v;
    const int right_v = right.u < right.v ? right.v : right.u;
    if (left_u != right_u) return left_u < right_u;
    return left_v < right_v;
}

int find_root(std::array<int, max_n> &parent, int value) noexcept {
    int root = value;
    while (parent[static_cast<std::size_t>(root)] != root)
        root = parent[static_cast<std::size_t>(root)];
    while (parent[static_cast<std::size_t>(value)] != value) {
        const int next = parent[static_cast<std::size_t>(value)];
        parent[static_cast<std::size_t>(value)] = root;
        value = next;
    }
    return root;
}
}

extern "C" std::int64_t manhattan_mst_candidate_edge_reduction(const std::int64_t *input,
                                                               std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 1 + 2 * max_n) return -1;
    if (input[0] < 0 || input[0] > max_n || length != 1 + 2 * static_cast<std::size_t>(input[0])) return -1;
    const int n = static_cast<int>(input[0]);
    std::array<Point, max_n> points{}, original{};
    std::array<std::uint64_t, 32> seen_x{}, seen_y{};
    for (int i = 0; i < n; ++i) {
        const std::int64_t x = input[1 + 2 * static_cast<std::size_t>(i)];
        const std::int64_t y = input[2 + 2 * static_cast<std::size_t>(i)];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000) return -1;
        const unsigned x_index = static_cast<unsigned>(static_cast<int>(x) + 1000);
        const unsigned y_index = static_cast<unsigned>(static_cast<int>(y) + 1000);
        const unsigned x_word = x_index >> 6, y_word = y_index >> 6;
        const std::uint64_t x_mask = std::uint64_t{1} << (x_index & 63);
        const std::uint64_t y_mask = std::uint64_t{1} << (y_index & 63);
        if ((seen_x[x_word] & x_mask) != 0 || (seen_y[y_word] & y_mask) != 0) return -1;
        seen_x[x_word] |= x_mask;
        seen_y[y_word] |= y_mask;
        points[static_cast<std::size_t>(i)] = {static_cast<int>(x), static_cast<int>(y), i};
        original[static_cast<std::size_t>(i)] = points[static_cast<std::size_t>(i)];
    }
    if (n < 2) return 0;

    std::array<Edge, max_candidates> candidates{};
    int candidate_count = 0;
    for (int direction = 0; direction < 4; ++direction) {
        std::array<Point, max_n> by_sum{}, by_x{};
        std::array<int, max_n> rank_by_id{};
        for (int i = 0; i < n; ++i)
            by_sum[static_cast<std::size_t>(i)] = by_x[static_cast<std::size_t>(i)] = points[static_cast<std::size_t>(i)];
        std::sort(by_sum.begin(), by_sum.begin() + n, point_sum_less);
        std::sort(by_x.begin(), by_x.begin() + n, point_x_less);
        for (int rank = 0; rank < n; ++rank)
            rank_by_id[static_cast<std::size_t>(by_x[static_cast<std::size_t>(rank)].id)] = rank;

        std::array<int, max_n + 1> active{};
        for (int i = 0; i < n; ++i) {
            const Point current = by_sum[static_cast<std::size_t>(i)];
            const int current_rank = rank_by_id[static_cast<std::size_t>(current.id)];
            int active_before = fenwick_prefix(active, current_rank + 1);
            while (active_before > 0) {
                const int candidate_rank = fenwick_kth(active, n, active_before);
                const int candidate_id = by_x[static_cast<std::size_t>(candidate_rank)].id;
                const Point candidate = points[static_cast<std::size_t>(candidate_id)];
                if (current.x - current.y > candidate.x - candidate.y) break;
                append_edge(candidates, candidate_count, original, current.id, candidate_id);
                fenwick_add(active, n, candidate_rank, -1);
                active_before = fenwick_prefix(active, current_rank + 1);
            }
            fenwick_add(active, n, current_rank, 1);
        }
        for (int i = 0; i < n; ++i) {
            Point &point = points[static_cast<std::size_t>(i)];
            if ((direction & 1) == 0) {
                const int old_x = point.x;
                point.x = point.y;
                point.y = old_x;
            } else {
                point.x = -point.x;
            }
        }
    }

    std::sort(candidates.begin(), candidates.begin() + candidate_count, edge_less);

    std::array<int, max_n> parent{}, component_size{};
    for (int i = 0; i < n; ++i) {
        parent[static_cast<std::size_t>(i)] = i;
        component_size[static_cast<std::size_t>(i)] = 1;
    }
    std::int64_t total = 0;
    int accepted = 0;
    for (int i = 0; i < candidate_count && accepted < n - 1; ++i) {
        const Edge edge = candidates[static_cast<std::size_t>(i)];
        const int root_u = find_root(parent, edge.u), root_v = find_root(parent, edge.v);
        if (root_u == root_v) continue;
        if (component_size[static_cast<std::size_t>(root_u)] < component_size[static_cast<std::size_t>(root_v)]) {
            parent[static_cast<std::size_t>(root_u)] = root_v;
            component_size[static_cast<std::size_t>(root_v)] += component_size[static_cast<std::size_t>(root_u)];
        } else {
            parent[static_cast<std::size_t>(root_v)] = root_u;
            component_size[static_cast<std::size_t>(root_u)] += component_size[static_cast<std::size_t>(root_v)];
        }
        total += edge.weight;
        ++accepted;
    }
    return accepted == n - 1 ? total : -1;
}
