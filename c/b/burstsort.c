#include <stddef.h>
#include <stdint.h>

#define BURST_MAX_STRINGS 16
#define BURST_MAX_STRING_LENGTH 8
#define BURST_MAX_NODES 129
#define BURST_THRESHOLD 3
#define BURST_MAX_INPUT_LENGTH 145

typedef struct {
    int depth;
    int burst;
    int leaf_count;
    int terminal_count;
    int children[4];
    int leaf_items[BURST_THRESHOLD];
    int terminal_items[BURST_MAX_STRINGS];
} BurstNode;

static int burst_new_node(BurstNode *nodes, int *used, int depth) {
    if (*used >= BURST_MAX_NODES) return -1;
    const int id = (*used)++;
    nodes[id].depth = depth;
    nodes[id].burst = 0;
    nodes[id].leaf_count = 0;
    nodes[id].terminal_count = 0;
    for (int key = 0; key < 4; ++key) nodes[id].children[key] = -1;
    return id;
}

static int burst_insert(BurstNode *nodes, int *used, int node_id, int depth,
                        int item, const int *string_lengths,
                        const int *string_bytes) {
    BurstNode *node = &nodes[node_id];
    if (string_lengths[item] == depth) {
        if (node->terminal_count >= BURST_MAX_STRINGS) return 0;
        node->terminal_items[node->terminal_count++] = item;
        return 1;
    }

    if (!node->burst && node->leaf_count < BURST_THRESHOLD) {
        node->leaf_items[node->leaf_count++] = item;
        return 1;
    }

    if (!node->burst) {
        int saved[BURST_THRESHOLD];
        const int saved_count = node->leaf_count;
        for (int i = 0; i < saved_count; ++i) saved[i] = node->leaf_items[i];
        node->leaf_count = 0;
        node->burst = 1;
        for (int i = 0; i < saved_count; ++i) {
            if (!burst_insert(nodes, used, node_id, depth, saved[i],
                              string_lengths, string_bytes)) return 0;
        }
    }

    const int key = string_bytes[item * BURST_MAX_STRING_LENGTH + depth];
    if (nodes[node_id].children[key] < 0) {
        const int child = burst_new_node(nodes, used, depth + 1);
        if (child < 0) return 0;
        nodes[node_id].children[key] = child;
    }
    return burst_insert(nodes, used, nodes[node_id].children[key], depth + 1,
                        item, string_lengths, string_bytes);
}

static int burst_string_less(int left, int right, const int *string_lengths,
                             const int *string_bytes) {
    const int left_length = string_lengths[left];
    const int right_length = string_lengths[right];
    const int common = left_length < right_length ? left_length : right_length;
    for (int i = 0; i < common; ++i) {
        const int a = string_bytes[left * BURST_MAX_STRING_LENGTH + i];
        const int b = string_bytes[right * BURST_MAX_STRING_LENGTH + i];
        if (a != b) return a < b;
    }
    return left_length < right_length;
}

static void burst_emit(const BurstNode *nodes, int node_id, int *output,
                       int *output_count, const int *string_lengths,
                       const int *string_bytes) {
    const BurstNode *node = &nodes[node_id];
    for (int i = 0; i < node->terminal_count; ++i)
        output[(*output_count)++] = node->terminal_items[i];

    if (node->burst) {
        for (int key = 0; key < 4; ++key) {
            if (node->children[key] >= 0)
                burst_emit(nodes, node->children[key], output, output_count,
                           string_lengths, string_bytes);
        }
        return;
    }

    int ordered[BURST_THRESHOLD];
    for (int i = 0; i < node->leaf_count; ++i) ordered[i] = node->leaf_items[i];
    for (int i = 1; i < node->leaf_count; ++i) {
        const int item = ordered[i];
        int position = i;
        while (position > 0 && burst_string_less(
                   item, ordered[position - 1], string_lengths, string_bytes)) {
            ordered[position] = ordered[position - 1];
            --position;
        }
        ordered[position] = item;
    }
    for (int i = 0; i < node->leaf_count; ++i)
        output[(*output_count)++] = ordered[i];
}

int64_t burstsort(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > BURST_MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > BURST_MAX_STRINGS) return -1;
    const int count = (int)input[0];
    int string_lengths[BURST_MAX_STRINGS] = {0};
    int string_bytes[BURST_MAX_STRINGS * BURST_MAX_STRING_LENGTH] = {0};

    size_t cursor = 1;
    for (int item = 0; item < count; ++item) {
        if (cursor >= length) return -1;
        const int64_t raw_length = input[cursor++];
        if (raw_length < 0 || raw_length > BURST_MAX_STRING_LENGTH) return -1;
        const int string_length = (int)raw_length;
        if ((size_t)string_length > length - cursor) return -1;
        string_lengths[item] = string_length;
        for (int j = 0; j < string_length; ++j) {
            const int64_t byte = input[cursor++];
            if (byte < 0 || byte > 3) return -1;
            string_bytes[item * BURST_MAX_STRING_LENGTH + j] = (int)byte;
        }
    }
    if (cursor != length) return -1;

    BurstNode nodes[BURST_MAX_NODES] = {0};
    int used = 0;
    const int root = burst_new_node(nodes, &used, 0);
    if (root < 0) return -1;
    for (int item = 0; item < count; ++item) {
        if (!burst_insert(nodes, &used, root, 0, item, string_lengths,
                          string_bytes)) return -1;
    }

    int sorted[BURST_MAX_STRINGS] = {0};
    int sorted_count = 0;
    burst_emit(nodes, root, sorted, &sorted_count, string_lengths, string_bytes);
    if (sorted_count != count) return -1;

    static const int64_t powers[8] = {78125, 15625, 3125, 625, 125, 25, 5, 1};
    int64_t checksum = 0;
    for (int rank = 0; rank < count; ++rank) {
        const int item = sorted[rank];
        int64_t key = 0;
        for (int j = 0; j < string_lengths[item]; ++j) {
            key += (int64_t)(string_bytes[item * BURST_MAX_STRING_LENGTH + j] + 1)
                   * powers[j];
        }
        checksum += (int64_t)(rank + 1) * key;
    }
    return checksum;
}
