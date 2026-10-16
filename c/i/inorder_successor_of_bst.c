#include <stddef.h>
#include <stdint.h>

enum { MAX_NODES = 64, MAX_INPUT_LENGTH = 67 };

int64_t inorder_successor_of_bst(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    const int64_t target = input[1];
    if (count_value < 0 || count_value > MAX_NODES || target < 1 || target > INT32_MAX ||
        length != (size_t)count_value + 2) return -1;

    const size_t count = (size_t)count_value;
    int64_t keys[MAX_NODES];
    int left[MAX_NODES], right[MAX_NODES];
    int root = -1;
    for (size_t index = 0; index < count; ++index) {
        const int64_t key = input[index + 2];
        if (key < 1 || key > INT32_MAX) return -1;
        for (size_t previous = 0; previous < index; ++previous) {
            if (keys[previous] == key) return -1;
        }
        keys[index] = key;
        left[index] = -1;
        right[index] = -1;
        const int node = (int)index;
        if (root < 0) {
            root = node;
            continue;
        }
        int current = root;
        for (;;) {
            if (key <= keys[current]) {
                if (left[current] < 0) {
                    left[current] = node;
                    break;
                }
                current = left[current];
            } else {
                if (right[current] < 0) {
                    right[current] = node;
                    break;
                }
                current = right[current];
            }
        }
    }

    int current = root;
    while (current >= 0 && keys[current] != target) {
        current = target > keys[current] ? right[current] : left[current];
    }
    if (current < 0) return 0;

    if (right[current] >= 0) {
        int successor = right[current];
        while (left[successor] >= 0) successor = left[successor];
        return keys[successor];
    }
    int successor = -1;
    int ancestor = root;
    while (ancestor >= 0 && ancestor != current) {
        if (keys[current] < keys[ancestor]) {
            successor = ancestor;
            ancestor = left[ancestor];
        } else {
            ancestor = right[ancestor];
        }
    }
    return successor < 0 ? 0 : keys[successor];
}
