#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_TARGET 127
#define MAX_OUTPUT_BYTES (8 * (MAX_TARGET + 1))

static size_t build_path(size_t target, size_t *path) {
    if (target == 1) {
        path[0] = 1;
        return 1;
    }
    size_t parent[MAX_TARGET + 1] = {0};
    bool seen[MAX_TARGET + 1] = {false};
    size_t queue[MAX_TARGET + 1] = {0};
    size_t reverse[MAX_TARGET + 1] = {0};
    size_t head = 0, tail = 1;
    queue[0] = 1;
    seen[1] = true;
    while (head < tail) {
        const size_t current = queue[head++];
        size_t chain_length = 0;
        for (size_t node = current; node != 0; node = parent[node])
            reverse[chain_length++] = node;
        for (size_t offset = 0; offset < chain_length; ++offset) {
            const size_t ancestor = reverse[chain_length - offset - 1];
            const size_t child = current + ancestor;
            if (child > target || seen[child]) continue;
            seen[child] = true;
            parent[child] = current;
            if (child == target) {
                size_t count = 0;
                for (size_t node = target; node != 0; node = parent[node])
                    path[count++] = node;
                for (size_t left = 0, right = count - 1; left < right; ++left, --right) {
                    const size_t temporary = path[left];
                    path[left] = path[right];
                    path[right] = temporary;
                }
                return count;
            }
            queue[tail++] = child;
        }
    }
    return 0;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t knuth_power_tree(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1 || input[0] < 1 || input[0] > MAX_TARGET) return -1;
    const size_t target = (size_t)input[0];
    size_t path[MAX_TARGET];
    const size_t path_length = build_path(target, path);
    const size_t required = 8 * (path_length + 1);
    if (output == NULL || capacity < required) return -2;
    store_i64_le(output, 0, (int64_t)(path_length - 1));
    for (size_t index = 0; index < path_length; ++index)
        store_i64_le(output, 8 * (index + 1), (int64_t)path[index]);
    return (int64_t)required;
}
