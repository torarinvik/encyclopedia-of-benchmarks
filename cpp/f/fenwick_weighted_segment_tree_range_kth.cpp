/* Mutable value trees stored at Fenwick position nodes for range selection. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 12, max_q = 16, value_count = 61, node_capacity = 1280;
struct Pool {
    int left[node_capacity + 1]{};
    int right[node_capacity + 1]{};
    int count[node_capacity + 1]{};
    int used = 0;
};

int change(Pool& pool, int root, int low, int high, int coordinate, int delta) noexcept {
    if (root == 0) root = ++pool.used;
    pool.count[root] += delta;
    if (high - low > 1) {
        const int middle = (low + high) / 2;
        if (coordinate < middle)
            pool.left[root] = change(pool, pool.left[root], low, middle, coordinate, delta);
        else
            pool.right[root] = change(pool, pool.right[root], middle, high, coordinate, delta);
    }
    return root;
}

void apply(Pool& pool, int roots[max_n + 1], int n, int position, int value, int delta) noexcept {
    for (int node = position + 1; node <= n; node += node & -node)
        roots[node] = change(pool, roots[node], 0, value_count, value + 30, delta);
}
}

extern "C" std::int64_t fenwick_weighted_segment_tree_range_kth(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 79) return INT64_MIN;
    if (input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_q) return INT64_MIN;
    const int n = static_cast<int>(input[0]), q = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + n + 4 * q)) return INT64_MIN;

    int current[max_n]{};
    int roots[max_n + 1]{};
    Pool pool{};
    for (int i = 0; i < n; ++i) {
        if (input[2 + i] < -30 || input[2 + i] > 30) return INT64_MIN;
        current[i] = static_cast<int>(input[2 + i]);
        apply(pool, roots, n, i, current[i], 1);
    }

    std::int64_t checksum = 0;
    int query_number = 0;
    std::size_t cursor = static_cast<std::size_t>(2 + n);
    for (int op = 0; op < q; ++op) {
        const auto opcode = input[cursor], first = input[cursor + 1];
        const auto second = input[cursor + 2], third = input[cursor + 3];
        cursor += 4;
        if (opcode == 0) {
            if (first < 0 || first >= n || second < -30 || second > 30 || third != 0) return INT64_MIN;
            const int position = static_cast<int>(first);
            apply(pool, roots, n, position, current[position], -1);
            current[position] = static_cast<int>(second);
            apply(pool, roots, n, position, current[position], 1);
        } else if (opcode == 1) {
            if (first < 0 || first >= second || second > n || third < 1 || third > second - first)
                return INT64_MIN;
            int left_roots[max_n + 1], right_roots[max_n + 1];
            int left_size = 0, right_size = 0;
            for (int node = static_cast<int>(first); node > 0; node -= node & -node)
                left_roots[left_size++] = roots[node];
            for (int node = static_cast<int>(second); node > 0; node -= node & -node)
                right_roots[right_size++] = roots[node];
            int low = 0, high = value_count;
            auto rank = third;
            while (high - low > 1) {
                const int middle = (low + high) / 2;
                std::int64_t left_count = 0;
                for (int i = 0; i < right_size; ++i) left_count += pool.count[pool.left[right_roots[i]]];
                for (int i = 0; i < left_size; ++i) left_count -= pool.count[pool.left[left_roots[i]]];
                if (rank <= left_count) {
                    for (int i = 0; i < right_size; ++i) right_roots[i] = pool.left[right_roots[i]];
                    for (int i = 0; i < left_size; ++i) left_roots[i] = pool.left[left_roots[i]];
                    high = middle;
                } else {
                    rank -= left_count;
                    for (int i = 0; i < right_size; ++i) right_roots[i] = pool.right[right_roots[i]];
                    for (int i = 0; i < left_size; ++i) left_roots[i] = pool.right[left_roots[i]];
                    low = middle;
                }
            }
            checksum += static_cast<std::int64_t>(query_number + 1) * (low - 30);
            ++query_number;
        } else {
            return INT64_MIN;
        }
    }
    return checksum;
}
