#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 130u
#define MAX_OPERATIONS 64u
#define MAX_LIST_LENGTH 64u
#define MAX_OUTPUT_FIELDS 194u

static void append_i64(int64_t *records, size_t *count, int64_t value)
{
    records[(*count)++] = value;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8u; ++byte) {
        output[offset + byte] = (uint8_t)bits;
        bits >>= 8u;
    }
}

int64_t self_organizing_linked_list(const int64_t *input, size_t length,
                                   uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation_count = input[0];
    if (operation_count < 0 || operation_count > (int64_t)MAX_OPERATIONS
        || length != 1u + 2u * (size_t)operation_count) return -1;

    int64_t items[MAX_LIST_LENGTH];
    int64_t records[MAX_OUTPUT_FIELDS];
    size_t item_count = 0u, record_count = 0u, cursor = 1u;
    for (int64_t step = 0; step < operation_count; ++step) {
        const int64_t opcode = input[cursor++];
        const int64_t value = input[cursor++];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (opcode == 0) {
            if (item_count == MAX_LIST_LENGTH) return -1;
            items[item_count++] = value;
            append_i64(records, &record_count, 0);
            append_i64(records, &record_count, 0);
        } else if (opcode == 1) {
            size_t found_at = 0u;
            while (found_at < item_count && items[found_at] != value) ++found_at;
            const int64_t found = found_at < item_count ? 1 : 0;
            append_i64(records, &record_count, 1);
            append_i64(records, &record_count, 1);
            append_i64(records, &record_count, found);
            if (found != 0 && found_at != 0u) {
                for (size_t index = found_at; index > 0u; --index)
                    items[index] = items[index - 1u];
                items[0] = value;
            }
        } else {
            return -1;
        }
    }

    append_i64(records, &record_count, 2);
    append_i64(records, &record_count, (int64_t)item_count);
    for (size_t index = 0; index < item_count; ++index)
        append_i64(records, &record_count, items[index]);

    const size_t output_bytes = record_count * 8u;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < record_count; ++index)
        write_i64_le(output, index * 8u, records[index]);
    return (int64_t)output_bytes;
}
