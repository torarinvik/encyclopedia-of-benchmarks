#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 128
#define MAX_ELEMENTS 64
#define MAX_INPUT_LENGTH (1 + 3 * MAX_OPERATIONS)
#define MAX_OUTPUT_WORDS (2 + MAX_OPERATIONS + MAX_ELEMENTS)

static void write_i64_le(uint8_t *output, size_t word_index, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[word_index * 8 + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t dynamic_array(const int64_t *input, size_t length,
                      uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;

    int64_t first[MAX_ELEMENTS] = {0};
    int64_t second[MAX_ELEMENTS] = {0};
    int64_t query_results[MAX_OPERATIONS] = {0};
    size_t active = 0;
    size_t size = 0;
    size_t capacity = 16;
    size_t cursor = 1;
    size_t query_count = 0;

    for (int64_t operation_index = 0; operation_index < operation_count_value; ++operation_index) {
        if (cursor >= length) return -1;
        const int64_t operation = input[cursor++];
        if (operation == 0) {
            if (cursor >= length || size >= MAX_ELEMENTS) return -1;
            const int64_t value = input[cursor++];
            if (size == capacity) {
                if (active == 0) {
                    for (size_t index = 0; index < size; ++index) second[index] = first[index];
                    active = 1;
                } else {
                    for (size_t index = 0; index < size; ++index) first[index] = second[index];
                    active = 0;
                }
                capacity *= 2;
            }
            if (active == 0) first[size] = value;
            else second[size] = value;
            ++size;
        } else if (operation == 1) {
            if (cursor + 1 >= length) return -1;
            const int64_t index_value = input[cursor++];
            const int64_t value = input[cursor++];
            if (index_value < 0 || (uint64_t)index_value >= size) return -1;
            if (active == 0) first[index_value] = value;
            else second[index_value] = value;
        } else if (operation == 2) {
            if (cursor >= length || query_count >= MAX_OPERATIONS) return -1;
            const int64_t index_value = input[cursor++];
            if (index_value < 0 || (uint64_t)index_value >= size) return -1;
            query_results[query_count++] = active == 0 ? first[index_value] : second[index_value];
        } else if (operation == 3) {
            if (query_count >= MAX_OPERATIONS) return -1;
            query_results[query_count++] = (int64_t)size;
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    const size_t output_words = 2 + query_count + size;
    const size_t output_bytes = output_words * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    write_i64_le(output, 0, (int64_t)query_count);
    for (size_t index = 0; index < query_count; ++index)
        write_i64_le(output, index + 1, query_results[index]);
    write_i64_le(output, query_count + 1, (int64_t)size);
    for (size_t index = 0; index < size; ++index) {
        const int64_t value = active == 0 ? first[index] : second[index];
        write_i64_le(output, query_count + 2 + index, value);
    }
    return (int64_t)output_words;
}
