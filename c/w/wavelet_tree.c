#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 64
#define MAX_QUERIES 128
#define MAX_NODES (12 * MAX_ITEMS)
#define MAX_PACKED_LENGTH (MAX_ITEMS + 2 + 5 * MAX_QUERIES)
#define CHECKSUM_OFFSET INT64_C(1000001)

typedef struct {
    int64_t low;
    int64_t high;
    int left;
    int right;
    size_t prefix_left[MAX_ITEMS + 1];
} WaveletNode;

static WaveletNode nodes[MAX_NODES];
static int used_nodes;

/* Build a stable value partition. prefix_left[k] counts left values in [0,k). */
static int build_tree(const int64_t *values, size_t length, int64_t low, int64_t high)
{
    int node_id = used_nodes++;
    WaveletNode *node = &nodes[node_id];
    node->low = low;
    node->high = high;
    node->left = -1;
    node->right = -1;
    node->prefix_left[0] = 0;

    if (low == high || length == 0) {
        return node_id;
    }

    int64_t middle = low + (high - low) / 2;
    int64_t left_values[MAX_ITEMS];
    int64_t right_values[MAX_ITEMS];
    size_t left_count = 0;
    size_t right_count = 0;

    for (size_t i = 0; i < length; ++i) {
        if (values[i] <= middle) {
            left_values[left_count++] = values[i];
        } else {
            right_values[right_count++] = values[i];
        }
        node->prefix_left[i + 1] = left_count;
    }

    if (left_count != 0) {
        node->left = build_tree(left_values, left_count, low, middle);
    }
    if (right_count != 0) {
        node->right = build_tree(right_values, right_count, middle + 1, high);
    }
    return node_id;
}

/* Count value occurrences in the first `count` positions of this node. */
static int64_t rank_prefix(int node_id, int64_t value, size_t count)
{
    if (node_id < 0 || count == 0) {
        return 0;
    }
    const WaveletNode *node = &nodes[node_id];
    if (node->low == node->high) {
        return node->low == value ? (int64_t)count : 0;
    }

    size_t left_count = node->prefix_left[count];
    int64_t middle = node->low + (node->high - node->low) / 2;
    if (value <= middle) {
        return rank_prefix(node->left, value, left_count);
    }
    return rank_prefix(node->right, value, count - left_count);
}

/* Return the zero-based kth value in the remapped half-open interval [left,right). */
static int64_t quantile(int node_id, size_t left, size_t right, size_t k)
{
    const WaveletNode *node = &nodes[node_id];
    if (node->low == node->high) {
        return node->low;
    }

    size_t left_before = node->prefix_left[left];
    size_t left_after = node->prefix_left[right];
    size_t in_left = left_after - left_before;
    if (k < in_left) {
        return quantile(node->left, left_before, left_after, k);
    }
    return quantile(node->right, left - left_before, right - left_after, k - in_left);
}

/* Count values in [value_low,value_high] for the remapped [left,right) interval. */
static int64_t range_count(int node_id, size_t left, size_t right,
                           int64_t value_low, int64_t value_high)
{
    if (node_id < 0 || left >= right) {
        return 0;
    }
    const WaveletNode *node = &nodes[node_id];
    if (value_high < node->low || value_low > node->high) {
        return 0;
    }
    if (value_low <= node->low && node->high <= value_high) {
        return (int64_t)(right - left);
    }
    if (node->low == node->high) {
        return 0;
    }

    size_t left_before = node->prefix_left[left];
    size_t left_after = node->prefix_left[right];
    return range_count(node->left, left_before, left_after, value_low, value_high)
         + range_count(node->right, left - left_before, right - left_after,
                       value_low, value_high);
}

int64_t wavelet_tree_benchmark(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_PACKED_LENGTH
        || values[0] < 1 || values[0] > MAX_ITEMS) {
        return -1;
    }

    size_t item_count = (size_t)values[0];
    if (length < item_count + 2) {
        return -1;
    }

    int64_t value_low = values[1];
    int64_t value_high = values[1];
    for (size_t i = 0; i < item_count; ++i) {
        int64_t value = values[i + 1];
        if (value < -1000 || value > 1000) {
            return -1;
        }
        if (value < value_low) value_low = value;
        if (value > value_high) value_high = value;
    }

    int64_t query_count_value = values[item_count + 1];
    if (query_count_value < 0 || query_count_value > MAX_QUERIES
        || length != item_count + 2 + 5 * (size_t)query_count_value) {
        return -1;
    }

    used_nodes = 0;
    int root = build_tree(values + 1, item_count, value_low, value_high);
    size_t query_count = (size_t)query_count_value;
    int64_t checksum = 0;

    for (size_t query_index = 0; query_index < query_count; ++query_index) {
        size_t offset = item_count + 2 + 5 * query_index;
        int64_t opcode = values[offset];
        int64_t a = values[offset + 1];
        int64_t b = values[offset + 2];
        int64_t c = values[offset + 3];
        int64_t d = values[offset + 4];
        int64_t answer;

        if (opcode == 0) {
            if (a < -1000 || a > 1000 || b < -1 || b >= (int64_t)item_count) {
                return -1;
            }
            answer = rank_prefix(root, a, (size_t)(b + 1));
        } else if (opcode == 1) {
            if (a < 0 || b < a || b >= (int64_t)item_count
                || c < 0 || c > b - a) {
                return -1;
            }
            answer = quantile(root, (size_t)a, (size_t)b + 1, (size_t)c);
        } else if (opcode == 2) {
            if (a < 0 || b < a || b >= (int64_t)item_count
                || c > d || c < -1000 || d > 1000) {
                return -1;
            }
            answer = range_count(root, (size_t)a, (size_t)b + 1, c, d);
        } else {
            return -1;
        }

        checksum += (int64_t)(query_index + 1) * (answer + CHECKSUM_OFFSET);
    }
    return checksum;
}
