#include <stddef.h>
#include <stdint.h>

#define MAX_CAPACITY 16
#define MAX_OPERATIONS 64
#define MAX_INPUT_LENGTH (2 + 2 * MAX_OPERATIONS)
#define MAX_OUTPUT_WORDS 65

static void selection_sort(uint64_t *items, size_t count) {
    for (size_t i = 0; i < count; ++i) {
        size_t minimum = i;
        for (size_t j = i + 1; j < count; ++j) {
            if (items[j] < items[minimum]) minimum = j;
        }
        uint64_t value = items[minimum];
        items[minimum] = items[i];
        items[i] = value;
    }
}

static int64_t binary_search(const uint64_t *items, size_t first, size_t last, uint64_t value) {
    if (last < first) return -1;
    size_t middle = (first + last) / 2;
    if (items[middle] == value) return (int64_t)middle;
    if (value < items[middle]) return binary_search(items, first, middle - 1, value);
    return binary_search(items, middle + 1, last, value);
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t list_array(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t capacity_value = input[0], operation_count_value = input[1];
    if (capacity_value < 1 || capacity_value > MAX_CAPACITY ||
        operation_count_value < 1 || operation_count_value > MAX_OPERATIONS) return -1;
    size_t capacity = (size_t)capacity_value, operations = (size_t)operation_count_value;
    if (length != 2 + 2 * operations) return -1;

    int64_t opcodes[MAX_OPERATIONS], arguments[MAX_OPERATIONS];
    int sorted = 0;
    for (size_t i = 0; i < operations; ++i) {
        int64_t opcode = input[2 + 2 * i], argument = input[3 + 2 * i];
        if (opcode == 0) {
            if (sorted || argument < 0) return -1;
        } else if (opcode == 1) {
            if (sorted || argument != 0) return -1;
            sorted = 1;
        } else if (opcode == 2 || opcode == 3) {
            if (!sorted || argument < 0) return -1;
        } else return -1;
        opcodes[i] = opcode;
        arguments[i] = argument;
    }
    if (!sorted) return -1;

    uint64_t items[MAX_CAPACITY] = {0};
    int64_t results[MAX_OPERATIONS] = {0};
    int64_t output_words[MAX_OUTPUT_WORDS] = {0};
    size_t count = 0, result_count = 0;
    for (size_t i = 0; i < operations; ++i) {
        int64_t opcode = opcodes[i], argument = arguments[i];
        if (opcode == 0) {
            if (count == capacity) return -1;
            items[count++] = (uint64_t)argument;
        } else if (opcode == 1) {
            selection_sort(items, count);
        } else {
            if (count == 0 || (uint64_t)argument < items[0]) return -1;
            if (opcode == 3 && count >= capacity) return -1;
            int64_t position = binary_search(items, 0, count - 1, (uint64_t)argument);
            results[result_count++] = position;
            if (opcode == 3 && position >= 0) {
                for (size_t j = (size_t)position; j < count; ++j) items[j] = items[j + 1];
                --count;
            }
        }
    }

    size_t word_count = 0;
    output_words[word_count++] = (int64_t)result_count;
    for (size_t i = 0; i < result_count; ++i) output_words[word_count++] = results[i];
    output_words[word_count++] = (int64_t)count;
    for (size_t i = 0; i < count; ++i) output_words[word_count++] = (int64_t)items[i];
    size_t required = word_count * 8;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t i = 0; i < word_count; ++i) put_i64_le(output, i * 8, output_words[i]);
    return (int64_t)required;
}
