/* Run bounded Java/JavaScript LRU cache traces and return operation records. */
#include <stddef.h>
#include <stdint.h>

#define MAX_CAPACITY 16
#define MAX_OPERATIONS 32
#define MAX_INPUT_LENGTH 99
#define MAX_OUTPUT_WORDS 130

int64_t lrucache(const int64_t *input, size_t input_length, uint8_t *output, size_t output_capacity) {
    if (!input || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1;
    int64_t capacity_value = input[0];
    int64_t operation_count_value = input[1];
    if (capacity_value < 2 || capacity_value > MAX_CAPACITY ||
        operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    size_t capacity = (size_t)capacity_value;
    size_t operation_count = (size_t)operation_count_value;
    if (input_length != 2 + 3 * operation_count) return -1;

    int64_t keys[MAX_CAPACITY] = {0};
    int64_t cached_values[MAX_CAPACITY] = {0};
    int64_t seen_put_keys[MAX_OPERATIONS] = {0};
    int64_t operation_records[3 * MAX_OPERATIONS] = {0};
    size_t used = 0;
    size_t seen_count = 0;

    for (size_t operation = 0; operation < operation_count; operation++) {
        int64_t opcode = input[2 + 3 * operation];
        int64_t key = input[3 + 3 * operation];
        int64_t value = input[4 + 3 * operation];
        if (opcode != 0 && opcode != 1) return -1;
        if (key < 0 || key > 1000000) return -1;

        int64_t returned_value = -1;
        int64_t evicted_key = -1;
        size_t position = 0;
        while (position < used && keys[position] != key) position++;

        if (opcode == 0) {
            if (value < 0 || value > 1000000) return -1;
            for (size_t prior = 0; prior < seen_count; prior++)
                if (seen_put_keys[prior] == key) return -1;
            seen_put_keys[seen_count++] = key;
            if (used == capacity) {
                evicted_key = keys[0];
                for (size_t index = 1; index < used; index++) {
                    keys[index - 1] = keys[index];
                    cached_values[index - 1] = cached_values[index];
                }
                used--;
            }
            keys[used] = key;
            cached_values[used] = value;
            used++;
        } else {
            if (value != 0 || position == used) return -1;
            returned_value = cached_values[position];
            for (size_t index = position + 1; index < used; index++) {
                keys[index - 1] = keys[index];
                cached_values[index - 1] = cached_values[index];
            }
            keys[used - 1] = key;
            cached_values[used - 1] = returned_value;
        }
        operation_records[3 * operation] = opcode;
        operation_records[3 * operation + 1] = returned_value;
        operation_records[3 * operation + 2] = evicted_key;
    }

    int64_t fields[MAX_OUTPUT_WORDS] = {0};
    size_t word_count = 0;
    fields[word_count++] = operation_count_value;
    for (size_t index = 0; index < 3 * operation_count; index++)
        fields[word_count++] = operation_records[index];
    fields[word_count++] = (int64_t)used;
    for (size_t index = used; index > 0; index--) {
        fields[word_count++] = keys[index - 1];
        fields[word_count++] = cached_values[index - 1];
    }

    size_t output_bytes = word_count * 8;
    if (!output || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < word_count; index++) {
        uint64_t bits = (uint64_t)fields[index];
        for (size_t byte = 0; byte < 8; byte++)
            output[index * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)output_bytes;
}
