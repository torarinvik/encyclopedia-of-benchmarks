#include <stddef.h>
#include <stdint.h>

int64_t xor_filter_peeling(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || input[0] < 0 || input[0] > 32 ||
        input[1] < 3 || input[1] > 96 || input[2] < 0 || input[2] > 32) return -1;
    int n = (int)input[0], slots = (int)input[1], q = (int)input[2];
    if (length != (size_t)(3 + 4*(n+q))) return -1;
    for (int i = 0; i < n+q; ++i) {
        const int64_t *r = input + 3 + 4*i;
        if (r[0] < 0 || r[0] >= slots || r[1] < 0 || r[1] >= slots ||
            r[2] < 0 || r[2] >= slots || r[0] == r[1] || r[0] == r[2] ||
            r[1] == r[2] || r[3] < 0 || r[3] > 255) return -1;
    }
    int degree[96] = {0}, edge_xor[96] = {0}, queue[96];
    int stack_slot[32], stack_edge[32], table[96] = {0};
    for (int edge = 0; edge < n; ++edge) {
        for (int j = 0; j < 3; ++j) {
            int slot = (int)input[3 + 4*edge + j];
            ++degree[slot];
            edge_xor[slot] ^= edge;
        }
    }
    int head = 0, tail = 0, used = 0;
    for (int slot = 0; slot < slots; ++slot) if (degree[slot] == 1) queue[tail++] = slot;
    while (head < tail) {
        int slot = queue[head++];
        if (degree[slot] != 1) continue;
        int edge = edge_xor[slot];
        stack_slot[used] = slot;
        stack_edge[used++] = edge;
        for (int j = 0; j < 3; ++j) {
            int v = (int)input[3 + 4*edge + j];
            --degree[v];
            edge_xor[v] ^= edge;
            if (degree[v] == 1) queue[tail++] = v;
        }
    }
    if (used != n) return -2;
    while (used > 0) {
        --used;
        int slot = stack_slot[used], edge = stack_edge[used];
        const int64_t *r = input + 3 + 4*edge;
        table[slot] = (int)r[3] ^ table[r[0]] ^ table[r[1]] ^ table[r[2]];
    }
    int64_t result = 0;
    for (int i = 0; i < q; ++i) {
        const int64_t *r = input + 3 + 4*(n+i);
        if ((table[r[0]] ^ table[r[1]] ^ table[r[2]]) == r[3]) result += i+1;
    }
    return result;
}
