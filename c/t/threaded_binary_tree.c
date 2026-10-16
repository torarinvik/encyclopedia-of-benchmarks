#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 128

typedef struct {
    int32_t key;
    int left;
    int right;
    bool left_is_thread;
    bool right_is_thread;
} Node;

static void put_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) {
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

int64_t threaded_binary_tree(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_NODES) return -1;
    const size_t count = (size_t)input[0];
    if (length != 1 + count) return -1;
    for (size_t i = 0; i < count; ++i) {
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
    }

    const size_t required = count * 4;
    if (required > 0 && (output == NULL || output_capacity < required)) return -2;

    Node nodes[MAX_NODES];
    int root = -1;
    for (size_t inserted = 0; inserted < count; ++inserted) {
        const int node = (int)inserted;
        const int32_t key = (int32_t)input[inserted + 1];
        nodes[node] = (Node){key, -1, -1, false, false};
        if (root == -1) {
            root = node;
            continue;
        }

        int current = root;
        int parent = -1;
        while (true) {
            parent = current;
            if (key < nodes[current].key) {
                if (!nodes[current].left_is_thread && nodes[current].left != -1) {
                    current = nodes[current].left;
                } else {
                    break;
                }
            } else {
                if (!nodes[current].right_is_thread && nodes[current].right != -1) {
                    current = nodes[current].right;
                } else {
                    break;
                }
            }
        }

        if (key < nodes[parent].key) {
            nodes[node].left = nodes[parent].left;
            nodes[node].left_is_thread = nodes[parent].left_is_thread;
            nodes[node].right = parent;
            nodes[node].right_is_thread = true;
            nodes[parent].left = node;
            nodes[parent].left_is_thread = false;
        } else {
            nodes[node].right = nodes[parent].right;
            nodes[node].right_is_thread = nodes[parent].right_is_thread;
            nodes[node].left = parent;
            nodes[node].left_is_thread = true;
            nodes[parent].right = node;
            nodes[parent].right_is_thread = false;
        }
    }

    int current = root;
    while (current != -1 && !nodes[current].left_is_thread && nodes[current].left != -1) {
        current = nodes[current].left;
    }
    size_t written = 0;
    while (current != -1) {
        put_i32_le(output, written, nodes[current].key);
        written += 4;
        if (nodes[current].right_is_thread) {
            current = nodes[current].right;
        } else {
            current = nodes[current].right;
            while (current != -1 && !nodes[current].left_is_thread && nodes[current].left != -1) {
                current = nodes[current].left;
            }
        }
    }
    return (int64_t)written;
}
