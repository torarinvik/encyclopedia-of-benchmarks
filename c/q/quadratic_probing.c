#include <stddef.h>
#include <stdint.h>

#define MIN_CAPACITY 5
#define MAX_CAPACITY 31
#define MAX_INSERT_COUNT 3
#define MAX_PARSEABLE_INPUT_LENGTH 5

static void write_i64_le(char *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        ((unsigned char *)output)[offset + byte] = (unsigned char)(bits & UINT64_C(0xff));
        bits >>= 8;
    }
}

int64_t quadratic_probing(const int64_t *input, size_t input_length,
                          char *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    const int64_t capacity_value = input[0];
    const int64_t insert_count_value = input[1];
    if (capacity_value < MIN_CAPACITY || capacity_value > MAX_CAPACITY ||
        insert_count_value < 0 || insert_count_value > MAX_INSERT_COUNT) return -1;

    const size_t capacity = (size_t)capacity_value;
    const size_t insert_count = (size_t)insert_count_value;
    if (input_length != 2 + insert_count) return -1;

    for (size_t i = 0; i < insert_count; ++i) {
        if (input[2 + i] < 0) return -1;
    }

    int64_t table[MAX_CAPACITY];
    for (size_t slot = 0; slot < capacity; ++slot) table[slot] = -1;

    for (size_t i = 0; i < insert_count; ++i) {
        const int64_t data = input[2 + i];
        const size_t home = (size_t)(data % (int64_t)capacity);
        if (table[home] == -1) {
            table[home] = data;
            continue;
        }
        if (table[home] == data) continue;

        size_t probe = 1;
        size_t slot = (home + probe * probe) % capacity;
        while (table[slot] != -1 && table[slot] != (int64_t)home) {
            ++probe;
            slot = (home + probe * probe) % capacity;
        }
        table[slot] = data;
    }

    const size_t output_bytes = 8 * (capacity + 1);
    if (output == NULL || output_capacity < output_bytes) return -2;
    write_i64_le(output, 0, (int64_t)capacity);
    for (size_t slot = 0; slot < capacity; ++slot) {
        write_i64_le(output, 8 * (slot + 1), table[slot]);
    }
    return (int64_t)output_bytes;
}
