#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 38
#define MAX_LEAVES 8

static void put_i64(uint8_t *out, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[b] = (uint8_t)(bits >> (8 * b));
}

int64_t felsenstein_substitution_likelihood(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t n = input[0];
    if (n < 1 || n > MAX_LEAVES) return -1;
    int64_t likelihood[MAX_LEAVES][2] = {{0}};
    size_t at = 1, stack_size = 0;
    int leaves = 0, joins = 0, edge_count = 0;
    while (at < length) {
        int64_t op = input[at++];
        if (op == 0) {
            if (at >= length || (input[at] != 0 && input[at] != 1) || stack_size >= MAX_LEAVES) return -1;
            int state = (int)input[at++];
            likelihood[stack_size][0] = state == 0 ? 1 : 0;
            likelihood[stack_size][1] = state == 1 ? 1 : 0;
            ++stack_size; ++leaves;
        } else if (op == 1) {
            if (at + 2 > length || stack_size < 2 ||
                (input[at] != 0 && input[at] != 1) || (input[at + 1] != 0 && input[at + 1] != 1)) return -1;
            int left_mode = (int)input[at++], right_mode = (int)input[at++];
            size_t left = stack_size - 2, right = stack_size - 1;
            int64_t next0[2], next1[2];
            for (int parent = 0; parent < 2; ++parent) {
                int64_t l = left_mode == 0 ? 4 * likelihood[left][parent] :
                    3 * likelihood[left][parent] + likelihood[left][1 - parent];
                int64_t r = right_mode == 0 ? 4 * likelihood[right][parent] :
                    3 * likelihood[right][parent] + likelihood[right][1 - parent];
                next0[parent] = l * r;
            }
            next1[0] = next0[0]; next1[1] = next0[1];
            likelihood[left][0] = next1[0]; likelihood[left][1] = next1[1];
            --stack_size; ++joins; edge_count += 2;
        } else return -1;
    }
    if (leaves != n || joins != n - 1 || stack_size != 1 || edge_count != 2 * n - 2) return -1;
    int shift = 29 - 2 * edge_count;
    if (shift < 0) return -1;
    int64_t scaled = (likelihood[0][0] + likelihood[0][1]) << shift;
    if (output == NULL || capacity < 8) return -2;
    put_i64(output, scaled);
    return 8;
}
