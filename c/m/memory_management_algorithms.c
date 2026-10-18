#include <stddef.h>
#include <stdint.h>

enum {
    MAX_BLOCK_COUNT = 16,
    MAX_PROCESS_COUNT = 32,
    MAX_INPUT_LENGTH = 52,
    MAX_OUTPUT_BYTES = 256,
    NO_ALLOCATION = -255
};

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (unsigned int byte = 0; byte < 8u; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(0xff));
        bits >>= 8u;
    }
}

int64_t memory_management_algorithms(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t policy_value = input[0];
    const int64_t block_count_value = input[1];
    const int64_t process_count_value = input[2];
    if (policy_value < 0 || policy_value > 3 || block_count_value < 1 || block_count_value > MAX_BLOCK_COUNT ||
        process_count_value < 0 || process_count_value > MAX_PROCESS_COUNT) return -1;
    const size_t block_count = (size_t)block_count_value;
    const size_t process_count = (size_t)process_count_value;
    if (length != 3u + block_count + process_count) return -1;

    int64_t blocks[MAX_BLOCK_COUNT] = {0};
    int64_t processes[MAX_PROCESS_COUNT] = {0};
    for (size_t index = 0; index < block_count; ++index) {
        const int64_t size = input[3u + index];
        if (size < 1 || size > 10000) return -1;
        blocks[index] = size;
    }
    for (size_t index = 0; index < process_count; ++index) {
        const int64_t size = input[3u + block_count + index];
        if (size < 1 || size > 10000) return -1;
        processes[index] = size;
    }

    int64_t allocations[MAX_PROCESS_COUNT] = {0};
    int64_t next_fit_counter = 0;
    for (size_t process_index = 0; process_index < process_count; ++process_index) {
        const int64_t process = processes[process_index];
        int64_t selected = NO_ALLOCATION;
        if (policy_value == 0) {
            for (size_t index = 0; index < block_count; ++index) {
                if (blocks[index] >= process) { selected = (int64_t)index; break; }
            }
        } else if (policy_value == 1) {
            int64_t min_diff = blocks[0];
            for (size_t index = 1; index < block_count; ++index)
                if (blocks[index] > min_diff) min_diff = blocks[index];
            for (size_t index = 0; index < block_count; ++index) {
                const int64_t difference = blocks[index] - process;
                if (difference < min_diff && difference >= 0) {
                    min_diff = difference;
                    selected = (int64_t)index;
                }
            }
        } else if (policy_value == 2) {
            size_t index = 0u;
            for (size_t candidate = 1; candidate < block_count; ++candidate)
                if (blocks[candidate] > blocks[index]) index = candidate;
            if (blocks[index] >= process) selected = (int64_t)index;
        } else {
            int found = 0;
            for (size_t offset = 0; offset < block_count; ++offset) {
                if (next_fit_counter + (int64_t)offset >= (int64_t)block_count)
                    next_fit_counter = -(int64_t)offset;
                const size_t index = (size_t)((int64_t)offset + next_fit_counter);
                if (blocks[index] >= process) {
                    next_fit_counter += (int64_t)offset;
                    selected = next_fit_counter;
                    found = 1;
                    break;
                }
            }
            if (!found) next_fit_counter += (int64_t)block_count;
        }
        allocations[process_index] = selected;
        if (selected != NO_ALLOCATION) blocks[(size_t)selected] -= process;
    }

    const size_t output_bytes = process_count * 8u;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < process_count; ++index)
        write_i64_le(output, index * 8u, allocations[index]);
    return (int64_t)output_bytes;
}
