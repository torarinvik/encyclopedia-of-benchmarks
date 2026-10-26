/* Static 2D range tree: x-rank segment tree with y-sorted node catalogs. */
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 8
#define MAX_QUERIES 8
#define MAX_INPUT_LENGTH 50
#define BASE 8
#define MAX_OUTPUT_WORDS 73

static int point_before(size_t left, size_t right,
                        const int64_t *xs, const int64_t *ys)
{
    return xs[left] < xs[right] ||
           (xs[left] == xs[right] && (ys[left] < ys[right] ||
            (ys[left] == ys[right] && left < right)));
}

static size_t lower_x(size_t *order, size_t n, const int64_t *xs, int64_t bound)
{
    size_t low = 0, high = n;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (xs[order[middle]] < bound) low = middle + 1;
        else high = middle;
    }
    return low;
}

static size_t upper_x(size_t *order, size_t n, const int64_t *xs, int64_t bound)
{
    size_t low = 0, high = n;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (xs[order[middle]] <= bound) low = middle + 1;
        else high = middle;
    }
    return low;
}

static size_t report_node(size_t node, const size_t tree_ids[16][8],
                          const size_t tree_size[16], const int64_t *ys,
                          int64_t y_low, int64_t y_high, size_t *hits)
{
    size_t low = 0, high = tree_size[node];
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (ys[tree_ids[node][middle]] < y_low) low = middle + 1;
        else high = middle;
    }
    const size_t first = low;
    high = tree_size[node];
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (ys[tree_ids[node][middle]] <= y_high) low = middle + 1;
        else high = middle;
    }
    for (size_t index = first; index < low; ++index) hits[index - first] = tree_ids[node][index];
    return low - first;
}

static void sort_ids(size_t *ids, size_t count)
{
    for (size_t index = 1; index < count; ++index) {
        const size_t item = ids[index];
        size_t position = index;
        while (position > 0 && ids[position - 1] > item) {
            ids[position] = ids[position - 1];
            --position;
        }
        ids[position] = item;
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255);
        bits >>= 8;
    }
}

int64_t orthogonal_range_reporting_2d(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_POINTS ||
        input[1] < 1 || input[1] > MAX_QUERIES) return -1;
    const size_t n = (size_t)input[0], q = (size_t)input[1];
    if (length != 2 + 2 * n + 4 * q) return -1;

    int64_t xs[MAX_POINTS], ys[MAX_POINTS];
    for (size_t point = 0; point < n; ++point) {
        xs[point] = input[2 + 2 * point];
        ys[point] = input[3 + 2 * point];
        if (xs[point] < 0 || xs[point] > 15 || ys[point] < 0 || ys[point] > 15) return -1;
        for (size_t earlier = 0; earlier < point; ++earlier) {
            if (xs[earlier] == xs[point] && ys[earlier] == ys[point]) return -1;
        }
    }
    int64_t queries[MAX_QUERIES][4];
    const size_t query_start = 2 + 2 * n;
    for (size_t query = 0; query < q; ++query) {
        for (size_t item = 0; item < 4; ++item) queries[query][item] = input[query_start + 4 * query + item];
        if (queries[query][0] < 0 || queries[query][0] > queries[query][1] || queries[query][1] > 15 ||
            queries[query][2] < 0 || queries[query][2] > queries[query][3] || queries[query][3] > 15) return -1;
    }

    size_t order[MAX_POINTS];
    for (size_t point = 0; point < n; ++point) order[point] = point;
    for (size_t index = 1; index < n; ++index) {
        const size_t item = order[index];
        size_t position = index;
        while (position > 0 && point_before(item, order[position - 1], xs, ys)) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = item;
    }

    size_t tree_ids[2 * BASE][MAX_POINTS] = {{0}};
    size_t tree_size[2 * BASE] = {0};
    for (size_t rank = 0; rank < n; ++rank) {
        tree_ids[BASE + rank][0] = order[rank];
        tree_size[BASE + rank] = 1;
    }
    for (size_t node = BASE - 1; node > 0; --node) {
        size_t left = 0, right = 0;
        const size_t left_node = node * 2, right_node = node * 2 + 1;
        while (left < tree_size[left_node] || right < tree_size[right_node]) {
            size_t chosen;
            if (right >= tree_size[right_node] ||
                (left < tree_size[left_node] &&
                 (ys[tree_ids[left_node][left]] < ys[tree_ids[right_node][right]] ||
                  (ys[tree_ids[left_node][left]] == ys[tree_ids[right_node][right]] &&
                   tree_ids[left_node][left] < tree_ids[right_node][right])))) {
                chosen = tree_ids[left_node][left++];
            } else {
                chosen = tree_ids[right_node][right++];
            }
            tree_ids[node][tree_size[node]++] = chosen;
        }
    }

    int64_t words[MAX_OUTPUT_WORDS];
    size_t cursor = 0;
    words[cursor++] = (int64_t)q;
    for (size_t query = 0; query < q; ++query) {
        size_t left = lower_x(order, n, xs, queries[query][0]);
        size_t right = upper_x(order, n, xs, queries[query][1]);
        size_t hits[MAX_POINTS];
        size_t hit_count = 0;
        left += BASE;
        right += BASE;
        while (left < right) {
            if (left & 1) {
                hit_count += report_node(left, tree_ids, tree_size, ys,
                    queries[query][2], queries[query][3], hits + hit_count);
                ++left;
            }
            if (right & 1) {
                --right;
                hit_count += report_node(right, tree_ids, tree_size, ys,
                    queries[query][2], queries[query][3], hits + hit_count);
            }
            left /= 2;
            right /= 2;
        }
        sort_ids(hits, hit_count);
        words[cursor++] = (int64_t)hit_count;
        for (size_t index = 0; index < hit_count; ++index) words[cursor++] = (int64_t)hits[index];
    }
    const size_t output_bytes = 8 * cursor;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t word = 0; word < cursor; ++word) store_i64_le(output, word * 8, words[word]);
    return (int64_t)output_bytes;
}
