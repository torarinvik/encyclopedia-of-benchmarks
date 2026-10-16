#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 64
#define MAX_INPUT_LENGTH (3 + 3 * MAX_NODES)

static void walk(size_t n, int64_t order, const int64_t *values, const int64_t *left,
                 const int64_t *right, size_t node, int64_t *out, size_t *used) {
    if (order == 0) out[(*used)++] = values[node];
    if (left[node] >= 0) walk(n, order, values, left, right, (size_t)left[node], out, used);
    if (order == 1) out[(*used)++] = values[node];
    if (right[node] >= 0) walk(n, order, values, left, right, (size_t)right[node], out, used);
    if (order == 2) out[(*used)++] = values[node];
}

static void breadth_first(int64_t order, const int64_t *values, const int64_t *left,
                          const int64_t *right, size_t root, int64_t *out, size_t *used) {
    size_t queue[MAX_NODES], head = 0, tail = 0;
    queue[tail++] = root;
    while (head < tail) {
        size_t node = queue[head++];
        out[(*used)++] = values[node];
        int64_t first = order == 3 ? left[node] : right[node];
        int64_t second = order == 3 ? right[node] : left[node];
        if (first >= 0) queue[tail++] = (size_t)first;
        if (second >= 0) queue[tail++] = (size_t)second;
    }
}

static void breadth_first_zigzag(const int64_t *values, const int64_t *left,
                                 const int64_t *right, size_t root, int64_t *out,
                                 size_t *used) {
    size_t queue[MAX_NODES], head = 0, tail = 0, level = 0;
    queue[tail++] = root;
    while (head < tail) {
        const size_t level_end = tail, start = *used;
        while (head < level_end) {
            const size_t node = queue[head++];
            out[(*used)++] = values[node];
            if (left[node] >= 0) queue[tail++] = (size_t)left[node];
            if (right[node] >= 0) queue[tail++] = (size_t)right[node];
        }
        if (level % 2 == 1) {
            size_t lo = start, hi = *used;
            while (lo < hi) {
                --hi;
                if (lo >= hi) break;
                const int64_t value = out[lo];
                out[lo++] = out[hi];
                out[hi] = value;
            }
        }
        ++level;
    }
}

static size_t mark_reachable(size_t n, const int64_t *left, const int64_t *right,
                             size_t root, uint8_t *seen) {
    size_t stack[MAX_NODES], top = 0, count = 0;
    stack[top++] = root;
    while (top) {
        size_t node = stack[--top];
        if (seen[node]) continue;
        seen[node] = 1;
        ++count;
        if (right[node] >= 0) stack[top++] = (size_t)right[node];
        if (left[node] >= 0) stack[top++] = (size_t)left[node];
    }
    return count;
}

static void put_i64(uint8_t *out, size_t index, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) out[index * 8 + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t binary_tree_traversal(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    int64_t order = input[0], count_value = input[1], root_value = input[2];
    if (order < 0 || order > 6 || count_value < 0 || count_value > MAX_NODES || length != 3 + 3 * (size_t)count_value) return -1;
    size_t n = (size_t)count_value;
    if (n == 0) {
        if (root_value != -1) return -1;
    } else if (root_value < 0 || root_value >= (int64_t)n) return -1;

    int64_t values[MAX_NODES] = {0}, left[MAX_NODES], right[MAX_NODES];
    uint8_t parents[MAX_NODES] = {0};
    for (size_t i = 0; i < n; ++i) {
        values[i] = input[3 + 3 * i];
        left[i] = input[4 + 3 * i];
        right[i] = input[5 + 3 * i];
        if (left[i] < -1 || left[i] >= (int64_t)n || right[i] < -1 || right[i] >= (int64_t)n || left[i] == (int64_t)i || right[i] == (int64_t)i) return -1;
        if (left[i] >= 0 && ++parents[left[i]] > 1) return -1;
        if (right[i] >= 0 && ++parents[right[i]] > 1) return -1;
    }
    int64_t result[MAX_NODES];
    size_t used = 0;
    if (n > 0) {
        size_t root = (size_t)root_value;
        for (size_t i = 0; i < n; ++i) if (parents[i] != (i == root ? 0 : 1)) return -1;
        uint8_t seen[MAX_NODES] = {0};
        if (mark_reachable(n, left, right, root, seen) != n) return -1;
        if (order <= 2) walk(n, order, values, left, right, root, result, &used);
        else if (order == 5) walk(n, 1, values, right, left, root, result, &used);
        else if (order == 6) breadth_first_zigzag(values, left, right, root, result, &used);
        else breadth_first(order, values, left, right, root, result, &used);
    }
    if (!output || capacity < used * 8) return -2;
    for (size_t i = 0; i < used; ++i) put_i64(output, i, result[i]);
    return (int64_t)(used * 8);
}
