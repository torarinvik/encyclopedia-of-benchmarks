#include <stddef.h>
#include <stdint.h>

enum { BLOCK_SIZE = 4, MAX_INITIAL = 16, MAX_OPS = 64, MAX_INSERTS = 32,
       MAX_ACCESSES = 32, MAX_NODES = 16, MAX_ITEMS = 48, MAX_PARSEABLE = 179 };

static int valid_input(const int64_t *input, size_t length, size_t *accesses) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE) return 0;
    const int64_t initial_arg = input[0];
    if (initial_arg < 0 || initial_arg > MAX_INITIAL) return 0;
    const size_t initial = (size_t)initial_arg;
    if (length < initial + 2) return 0;
    for (size_t i = 0; i < initial; ++i)
        if (input[1 + i] < -1000000 || input[1 + i] > 1000000) return 0;
    const int64_t operation_arg = input[1 + initial];
    if (operation_arg < 0 || operation_arg > MAX_OPS) return 0;
    size_t cursor = initial + 2, size = initial, inserts = 0;
    *accesses = 0;
    for (size_t op = 0; op < (size_t)operation_arg; ++op) {
        if (cursor >= length) return 0;
        const int64_t opcode = input[cursor];
        if (opcode == 0) {
            if (cursor + 3 > length) return 0;
            const int64_t index = input[cursor + 1], value = input[cursor + 2];
            if (index < 0 || (uint64_t)index > (uint64_t)size || value < -1000000 || value > 1000000) return 0;
            if (++inserts > MAX_INSERTS) return 0;
            ++size;
            cursor += 3;
        } else if (opcode == 1) {
            if (cursor + 2 > length) return 0;
            const int64_t index = input[cursor + 1];
            if (index < 0 || (uint64_t)index >= (uint64_t)size) return 0;
            if (++*accesses > MAX_ACCESSES) return 0;
            cursor += 2;
        } else return 0;
    }
    return cursor == length && size <= MAX_ITEMS;
}

static void block_insert(int64_t blocks[MAX_NODES][2 * BLOCK_SIZE + 1], size_t sizes[MAX_NODES],
                         int next[MAX_NODES], size_t *node_count, size_t index, int64_t value) {
    int node = 0;
    size_t offset = 0;
    while (next[node] >= 0 && index > offset + sizes[node]) {
        offset += sizes[node];
        node = next[node];
    }
    const size_t local = index - offset;
    for (size_t j = sizes[node]; j > local; --j) blocks[node][j] = blocks[node][j - 1];
    blocks[node][local] = value;
    ++sizes[node];
    if (sizes[node] > 2 * BLOCK_SIZE) {
        const int fresh = (int)(*node_count);
        ++*node_count;
        const size_t first_moved = sizes[node] - BLOCK_SIZE;
        for (size_t j = 0; j < BLOCK_SIZE; ++j) blocks[fresh][j] = blocks[node][first_moved + j];
        sizes[fresh] = BLOCK_SIZE;
        sizes[node] -= BLOCK_SIZE;
        next[fresh] = next[node];
        next[node] = fresh;
    }
}

static int64_t block_get(int64_t blocks[MAX_NODES][2 * BLOCK_SIZE + 1], size_t sizes[MAX_NODES],
                         int next[MAX_NODES], size_t index) {
    int node = 0;
    size_t offset = 0;
    while (index >= offset + sizes[node]) {
        offset += sizes[node];
        node = next[node];
    }
    return blocks[node][index - offset];
}

int64_t indexed_block_list(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    size_t access_count = 0;
    if (!valid_input(input, length, &access_count)) return -1;
    if (access_count == 0) return 0;
    const size_t required = access_count * 8;
    if (output == NULL || capacity < required) return -2;

    int64_t blocks[MAX_NODES][2 * BLOCK_SIZE + 1] = {{0}};
    size_t sizes[MAX_NODES] = {0};
    int next[MAX_NODES];
    for (size_t i = 0; i < MAX_NODES; ++i) next[i] = -1;
    size_t node_count = 1;
    const size_t initial = (size_t)input[0];
    for (size_t i = 0; i < initial; ++i) block_insert(blocks, sizes, next, &node_count, i, input[1 + i]);

    const size_t operation_count = (size_t)input[1 + initial];
    size_t cursor = initial + 2, answer_count = 0;
    int64_t answers[MAX_ACCESSES] = {0};
    for (size_t op = 0; op < operation_count; ++op) {
        const int64_t opcode = input[cursor];
        const size_t index = (size_t)input[cursor + 1];
        if (opcode == 0) {
            block_insert(blocks, sizes, next, &node_count, index, input[cursor + 2]);
            cursor += 3;
        } else {
            answers[answer_count++] = block_get(blocks, sizes, next, index);
            cursor += 2;
        }
    }
    for (size_t i = 0; i < answer_count; ++i) {
        const uint64_t bits = (uint64_t)answers[i];
        for (size_t byte = 0; byte < 8; ++byte) output[8 * i + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)required;
}
