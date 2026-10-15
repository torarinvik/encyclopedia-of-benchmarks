/* Emit rows in the pinned Rust Heap permutation routine's exact swap-before-recursion order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 7
#define BYTES_PER_VALUE 4

static void store_i32_le(uint8_t *output, size_t offset, int32_t value) {
    uint32_t bits = (uint32_t)value;
    for (size_t b = 0; b < 4; ++b) output[offset + b] = (uint8_t)(bits >> (8 * b));
}
static void generate(int32_t *values, size_t n, size_t k, uint8_t *output, size_t *rows) {
    if (k == 1) {
        size_t start = *rows * n * BYTES_PER_VALUE;
        for (size_t j = 0; j < n; ++j) store_i32_le(output, start + j * BYTES_PER_VALUE, values[j]);
        ++*rows;
        return;
    }
    for (size_t i = 0; i < k; ++i) {
        size_t swap_index = k % 2 == 0 ? i : 0;
        int32_t tmp = values[swap_index]; values[swap_index] = values[k - 1]; values[k - 1] = tmp;
        generate(values, n, k - 1, output, rows);
    }
}
int64_t heap_permutation(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_LENGTH + 1) return -1;
    int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_LENGTH || length != (size_t)n_value + 1) return -1;
    size_t n = (size_t)n_value;
    int32_t values[MAX_LENGTH];
    for (size_t i = 0; i < n; ++i) { int64_t v=input[i+1]; if(v<INT32_MIN||v>INT32_MAX)return -1; values[i]=(int32_t)v; }
    size_t permutations=1;for(size_t factor=2;factor<=n;++factor)permutations*=factor;
    size_t required=permutations*n*BYTES_PER_VALUE;
    if(capacity<required||(required!=0&&output==NULL))return -2;
    if(n==0)return 1;
    size_t rows=0;generate(values,n,n,output,&rows);return (int64_t)rows;
}
