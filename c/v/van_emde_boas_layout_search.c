#include <stddef.h>
#include <stdint.h>

enum { VEB_MAX_HEIGHT = 4, VEB_MAX_NODES = 15, VEB_MAX_QUERIES = 4,
       VEB_MAX_WORDS = 41, VEB_MAX_PARSEABLE = 2 + VEB_MAX_QUERIES + 1 };

static void veb_fill_keys(int64_t keys[VEB_MAX_NODES + 1], int heap,
                          int low, int high) {
    if (low > high) return;
    int middle = low + (high - low) / 2;
    keys[heap] = middle;
    veb_fill_keys(keys, 2 * heap, low, middle - 1);
    veb_fill_keys(keys, 2 * heap + 1, middle + 1, high);
}

static void veb_emit(int64_t order[VEB_MAX_NODES], int *used,
                     int root, int height) {
    if (height == 1) {
        order[(*used)++] = root;
        return;
    }
    int top_height = height / 2;
    int bottom_height = height - top_height;
    veb_emit(order, used, root, top_height);
    int bottom_count = 1 << top_height;
    int first_bottom = root * bottom_count;
    for (int offset = 0; offset < bottom_count; ++offset)
        veb_emit(order, used, first_bottom + offset, bottom_height);
}

int64_t van_emde_boas_layout_search(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > VEB_MAX_PARSEABLE) return -1;
    int64_t height_value = input[0];
    int64_t query_count_value = input[1];
    if (height_value < 1 || height_value > VEB_MAX_HEIGHT ||
        query_count_value < 0 || query_count_value > VEB_MAX_QUERIES) return -1;
    int height = (int)height_value;
    int query_count = (int)query_count_value;
    if (length != (size_t)(2 + query_count)) return -1;
    int node_count = (1 << height) - 1;
    for (int query = 0; query < query_count; ++query)
        if (input[2 + query] < -1 || input[2 + query] > node_count) return -1;

    int64_t order[VEB_MAX_NODES] = {0};
    int64_t keys[VEB_MAX_NODES + 1] = {0};
    int64_t slots[VEB_MAX_NODES + 1] = {0};
    int64_t staged[VEB_MAX_WORDS] = {0};
    int used = 0;
    veb_emit(order, &used, 1, height);
    veb_fill_keys(keys, 1, 0, node_count - 1);
    for (int slot = 0; slot < node_count; ++slot)
        slots[order[slot]] = slot;

    int out = 0;
    staged[out++] = node_count;
    for (int slot = 0; slot < node_count; ++slot) staged[out++] = order[slot];
    staged[out++] = query_count;
    for (int query = 0; query < query_count; ++query) {
        int64_t key = input[2 + query];
        int heap = 1;
        int path_start = out++;
        int path_length = 0;
        int64_t found = -1;
        while (heap <= node_count) {
            staged[out++] = slots[heap];
            ++path_length;
            if (key == keys[heap]) {
                found = heap;
                break;
            }
            heap = key < keys[heap] ? 2 * heap : 2 * heap + 1;
        }
        staged[path_start] = path_length;
        staged[out++] = found;
    }
    size_t required = (size_t)out * 8;
    if (output == NULL || capacity < required) return -2;
    for (int word = 0; word < out; ++word) {
        uint64_t bits = (uint64_t)staged[word];
        for (int byte = 0; byte < 8; ++byte)
            output[(size_t)word * 8 + (size_t)byte] =
                (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)required;
}
