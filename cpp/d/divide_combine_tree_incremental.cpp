#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_N = 16;
constexpr int MAX_NODES = 2 * MAX_N - 1;
constexpr int TREE_SIZE = 4 * MAX_N + 4;

void add(int node, int left, int right, int ql, int qr, int delta,
         std::array<int, TREE_SIZE>& minimum, std::array<int, TREE_SIZE>& lazy) {
    if (ql <= left && right <= qr) {
        minimum[node] += delta;
        lazy[node] += delta;
        return;
    }
    const int middle = (left + right) / 2;
    if (lazy[node] != 0) {
        const int tag = lazy[node];
        minimum[node * 2] += tag;
        minimum[node * 2 + 1] += tag;
        lazy[node * 2] += tag;
        lazy[node * 2 + 1] += tag;
        lazy[node] = 0;
    }
    if (ql <= middle && qr >= left) add(node * 2, left, middle, ql, qr, delta, minimum, lazy);
    if (qr > middle && ql <= right) add(node * 2 + 1, middle + 1, right, ql, qr, delta, minimum, lazy);
    minimum[node] = minimum[node * 2] < minimum[node * 2 + 1]
        ? minimum[node * 2] : minimum[node * 2 + 1];
}

int first_zero(int node, int left, int right, const std::array<int, TREE_SIZE>& minimum) {
    if (left == right) return left;
    const int middle = (left + right) / 2;
    if (minimum[node * 2] == 0) return first_zero(node * 2, left, middle, minimum);
    return first_zero(node * 2 + 1, middle + 1, right, minimum);
}

bool connected(int left, int right, const std::array<int, MAX_N + 1>& logs,
               const std::array<int, MAX_N * MAX_N>& range_min,
               const std::array<int, MAX_N * MAX_N>& range_max) {
    const int level = logs[right - left + 1];
    const int span = 1 << level;
    const int other = right - span + 1;
    const int low = range_min[level * MAX_N + left] < range_min[level * MAX_N + other]
        ? range_min[level * MAX_N + left] : range_min[level * MAX_N + other];
    const int high = range_max[level * MAX_N + left] > range_max[level * MAX_N + other]
        ? range_max[level * MAX_N + left] : range_max[level * MAX_N + other];
    return high - low == right - left;
}
}

extern "C" std::int64_t divide_combine_tree_incremental(const std::int64_t* input,
                                                          std::size_t length) {
    if (input == nullptr || length < 1 || length > MAX_N + 2) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length != static_cast<std::size_t>(n_value + 1)) return -1;
    const int n = static_cast<int>(n_value);
    std::array<int, MAX_N> permutation{};
    std::array<bool, MAX_N> seen{};
    for (int i = 0; i < n; ++i) {
        const std::int64_t value = input[i + 1];
        if (value < 0 || value >= n || seen[static_cast<std::size_t>(value)]) return -1;
        permutation[i] = static_cast<int>(value);
        seen[static_cast<std::size_t>(value)] = true;
    }

    std::array<int, MAX_N + 1> logs{};
    for (int i = 2; i <= n; ++i) logs[i] = logs[i / 2] + 1;
    const int levels = logs[n] + 1;
    std::array<int, MAX_N * MAX_N> range_min{};
    std::array<int, MAX_N * MAX_N> range_max{};
    for (int i = 0; i < n; ++i) {
        range_min[i] = permutation[i];
        range_max[i] = permutation[i];
    }
    for (int level = 1; level < levels; ++level) {
        const int half = 1 << (level - 1);
        const int width = half * 2;
        for (int start = 0; start + width <= n; ++start) {
            const int low_a = range_min[(level - 1) * MAX_N + start];
            const int low_b = range_min[(level - 1) * MAX_N + start + half];
            range_min[level * MAX_N + start] = low_a < low_b ? low_a : low_b;
            const int high_a = range_max[(level - 1) * MAX_N + start];
            const int high_b = range_max[(level - 1) * MAX_N + start + half];
            range_max[level * MAX_N + start] = high_a > high_b ? high_a : high_b;
        }
    }

    std::array<int, TREE_SIZE> segment_min{};
    std::array<int, TREE_SIZE> lazy{};
    std::array<int, MAX_NODES> node_left{}, node_right{}, node_combine{}, node_last{};
    std::array<int, MAX_N> node_stack{}, min_stack{}, max_stack{};
    int node_top = 0, min_top = 0, max_top = 0, node_count = 0;
    auto new_node = [&](int left, int right, int is_combine, int last_left) {
        const int id = node_count++;
        node_left[id] = left;
        node_right[id] = right;
        node_combine[id] = is_combine;
        node_last[id] = last_left;
        return id;
    };

    for (int end = 0; end < n; ++end) {
        const int value = permutation[end];
        while (min_top > 0 && permutation[min_stack[min_top - 1]] >= value) {
            const int position = min_stack[--min_top];
            const int start = min_top > 0 ? min_stack[min_top - 1] + 1 : 0;
            add(1, 0, n - 1, start, position, permutation[position], segment_min, lazy);
        }
        while (max_top > 0 && permutation[max_stack[max_top - 1]] <= value) {
            const int position = max_stack[--max_top];
            const int start = max_top > 0 ? max_stack[max_top - 1] + 1 : 0;
            add(1, 0, n - 1, start, position, -permutation[position], segment_min, lazy);
        }
        int start = min_top > 0 ? min_stack[min_top - 1] + 1 : 0;
        add(1, 0, n - 1, start, end, -value, segment_min, lazy);
        min_stack[min_top++] = end;
        start = max_top > 0 ? max_stack[max_top - 1] + 1 : 0;
        add(1, 0, n - 1, start, end, value, segment_min, lazy);
        max_stack[max_top++] = end;

        const int leftmost = first_zero(1, 0, n - 1, segment_min);
        int current = new_node(end, end, 0, 0);
        while (node_top > 0 && node_left[node_stack[node_top - 1]] >= leftmost) {
            const int top = node_stack[node_top - 1];
            if (node_combine[top] && connected(node_last[top], end, logs, range_min, range_max)) {
                node_right[top] = end;
                node_last[top] = node_left[current];
                current = node_stack[--node_top];
            } else if (connected(node_left[top], end, logs, range_min, range_max)) {
                const int merged = new_node(node_left[top], end, 1, node_left[current]);
                --node_top;
                current = merged;
            } else {
                const int merged = new_node(-1, end, 0, 0);
                do { --node_top; }
                while (node_top > 0
                       && !connected(node_left[node_stack[node_top - 1]], end,
                                     logs, range_min, range_max));
                if (node_top == 0) return -1;
                const int base = node_stack[--node_top];
                node_left[merged] = node_left[base];
                current = merged;
            }
        }
        node_stack[node_top++] = current;
        add(1, 0, n - 1, 0, end, -1, segment_min, lazy);
    }

    for (int i = 1; i < node_count; ++i) {
        const int left = node_left[i], right = node_right[i];
        int j = i;
        while (j > 0 && (node_left[j - 1] > left
                         || (node_left[j - 1] == left && node_right[j - 1] > right))) {
            node_left[j] = node_left[j - 1];
            node_right[j] = node_right[j - 1];
            --j;
        }
        node_left[j] = left;
        node_right[j] = right;
    }
    std::int64_t checksum = 0;
    for (int i = 0; i < node_count; ++i) {
        checksum += static_cast<std::int64_t>(i + 1)
            * (static_cast<std::int64_t>(node_left[i] + 1) * (n + 1)
               + node_right[i] + 1);
    }
    return checksum;
}
