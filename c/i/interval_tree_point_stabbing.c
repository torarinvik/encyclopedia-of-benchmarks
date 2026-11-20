#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_Q = 8, MAX_INPUT = 43, TREE_CAP = 32, MAX_OUTPUT = 72 };
typedef struct { int64_t low, high; int id; } Interval;

static void place_balanced(const Interval *sorted, Interval *tree, uint8_t *used,
                           int first, int last, int node) {
    if (first > last || node >= TREE_CAP) return;
    int middle = first + (last - first) / 2;
    tree[node] = sorted[middle];
    used[node] = 1;
    place_balanced(sorted, tree, used, first, middle - 1, 2 * node + 1);
    place_balanced(sorted, tree, used, middle + 1, last, 2 * node + 2);
}

static void write_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        out[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t interval_tree_point_stabbing(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], q64 = input[1];
    if (n64 < 0 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q) return -1;
    int n = (int)n64, q = (int)q64;
    if (length != (size_t)(2 + 2 * n + q)) return -1;
    Interval sorted[MAX_N] = {{0, 0, 0}};
    size_t at = 2;
    for (int i = 0; i < n; ++i) {
        int64_t low = input[at++], high = input[at++];
        if (low < -32 || low > 32 || high < -32 || high > 32 || low > high) return -1;
        sorted[i] = (Interval){low, high, i};
    }
    int64_t points[MAX_Q] = {0};
    for (int i = 0; i < q; ++i) {
        points[i] = input[at++];
        if (points[i] < -32 || points[i] > 32) return -1;
    }
    for (int i = 1; i < n; ++i) {
        Interval value = sorted[i];
        int j = i;
        while (j > 0 && (sorted[j - 1].low > value.low ||
               (sorted[j - 1].low == value.low && sorted[j - 1].high > value.high) ||
               (sorted[j - 1].low == value.low && sorted[j - 1].high == value.high &&
                sorted[j - 1].id > value.id))) {
            sorted[j] = sorted[j - 1];
            --j;
        }
        sorted[j] = value;
    }
    Interval tree[TREE_CAP] = {{0, 0, 0}};
    uint8_t used[TREE_CAP] = {0};
    int64_t maximum[TREE_CAP];
    for (int i = 0; i < TREE_CAP; ++i) maximum[i] = INT64_MIN;
    if (n != 0) place_balanced(sorted, tree, used, 0, n - 1, 0);
    for (int node = TREE_CAP - 1; node >= 0; --node) {
        if (!used[node]) continue;
        maximum[node] = tree[node].high;
        int left = 2 * node + 1, right = left + 1;
        if (left < TREE_CAP && used[left] && maximum[left] > maximum[node]) maximum[node] = maximum[left];
        if (right < TREE_CAP && used[right] && maximum[right] > maximum[node]) maximum[node] = maximum[right];
    }
    int64_t masks[MAX_Q] = {0};
    for (int qi = 0; qi < q; ++qi) {
        int stack[TREE_CAP], top = 0;
        if (n != 0) stack[top++] = 0;
        while (top > 0) {
            int node = stack[--top];
            if (!used[node] || maximum[node] < points[qi]) continue;
            int left = 2 * node + 1, right = left + 1;
            if (left < TREE_CAP && used[left] && maximum[left] >= points[qi]) stack[top++] = left;
            if (tree[node].low <= points[qi] && points[qi] <= tree[node].high)
                masks[qi] |= (int64_t)(UINT64_C(1) << tree[node].id);
            if (tree[node].low <= points[qi] && right < TREE_CAP && used[right] && maximum[right] >= points[qi])
                stack[top++] = right;
        }
    }
    size_t bytes = (size_t)(q + 1) * 8;
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT] = {0};
    write_i64_le(staged, 0, q);
    for (int i = 0; i < q; ++i) write_i64_le(staged, (size_t)(i + 1) * 8, masks[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
