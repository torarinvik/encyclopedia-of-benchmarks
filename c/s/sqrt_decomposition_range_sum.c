/* Integer sum specialization of the pinned square-root decomposition. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_OPERATIONS 64
#define MAX_INPUT_LENGTH 258
#define VALUE_MIN (-1000)
#define VALUE_MAX 1000

static size_t block_size_for(size_t n)
{
    size_t block_size = 1;
    while ((block_size + 1) * (block_size + 1) <= n) ++block_size;
    return block_size;
}

static int64_t query_sum(const int64_t *elements, const int64_t *blocks,
                         size_t block_size, size_t start, size_t end)
{
    const size_t first_index_next_block = ((start / block_size) + 1) * block_size;
    int64_t sum = elements[start];
    if (first_index_next_block > end) {
        for (size_t index = start + 1; index < end; ++index) sum += elements[index];
    } else {
        for (size_t index = start + 1; index < first_index_next_block; ++index)
            sum += elements[index];
        const size_t end_block = end / block_size;
        for (size_t block = first_index_next_block / block_size; block < end_block; ++block)
            sum += blocks[block];
        for (size_t index = end_block * block_size; index < end; ++index)
            sum += elements[index];
    }
    return sum;
}

int64_t sqrt_decomposition_range_sum(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length < n + 2) return -1;
    if (input[n + 1] < 0 || input[n + 1] > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[n + 1];
    if (length != 2 + n + 3 * operation_count) return -1;

    int64_t elements[MAX_N];
    for (size_t index = 0; index < n; ++index) {
        const int64_t value = input[index + 1];
        if (value < VALUE_MIN || value > VALUE_MAX) return -1;
        elements[index] = value;
    }

    size_t query_count = 0;
    const size_t operations_start = n + 2;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t offset = operations_start + 3 * operation;
        const int64_t kind = input[offset];
        const int64_t first = input[offset + 1];
        const int64_t second = input[offset + 2];
        if (kind == 0) {
            if (first < 0 || first >= second || second > (int64_t)n) return -1;
            ++query_count;
        } else if (kind == 1) {
            if (first < 0 || first >= (int64_t)n || second < VALUE_MIN || second > VALUE_MAX)
                return -1;
        } else {
            return -1;
        }
    }

    const size_t output_bytes = query_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;

    const size_t block_size = block_size_for(n);
    int64_t blocks[MAX_N] = {0};
    for (size_t index = 0; index < n; ++index) {
        const size_t block = index / block_size;
        if (index % block_size == 0) blocks[block] = elements[index];
        else blocks[block] += elements[index];
    }

    size_t output_offset = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t offset = operations_start + 3 * operation;
        const int64_t kind = input[offset];
        const size_t first = (size_t)input[offset + 1];
        const int64_t second = input[offset + 2];
        if (kind == 0) {
            const int64_t sum = query_sum(elements, blocks, block_size, first, (size_t)second);
            uint64_t bits = (uint64_t)sum;
            for (size_t byte = 0; byte < 8; ++byte) {
                output[output_offset++] = (uint8_t)(bits & 255);
                bits >>= 8;
            }
        } else {
            const size_t block = first / block_size;
            blocks[block] = blocks[block] - elements[first] + second;
            elements[first] = second;
        }
    }
    return (int64_t)output_bytes;
}
