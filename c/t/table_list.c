#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 32
#define MAX_INPUT_LENGTH 98u
#define MAX_OUTPUT_FIELDS 594u
#define MIN_VALUE INT64_C(-1000000)
#define MAX_VALUE INT64_C(1000000)

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)bits;
        bits >>= 8;
    }
}

static void append(int64_t *records, size_t *count, int64_t value)
{
    records[(*count)++] = value;
}

int64_t table_list(const int64_t *input, size_t length,
                   uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation_count = input[0];
    if (operation_count < 0 || operation_count > MAX_OPERATIONS
        || length != 1u + 3u * (size_t)operation_count) return -1;

    int64_t items[64] = {0};
    int64_t records[MAX_OUTPUT_FIELDS];
    size_t head = 32u, item_count = 0u, record_count = 0u;
    size_t cursor = 1u;
    for (int64_t step = 0; step < operation_count; ++step) {
        const int64_t opcode = input[cursor++];
        const int64_t arg1 = input[cursor++];
        const int64_t arg2 = input[cursor++];
        switch (opcode) {
        case 0: /* push_head */
            if (arg1 < MIN_VALUE || arg1 > MAX_VALUE || arg2 != 0 || item_count >= 32u) return -1;
            items[--head] = arg1;
            ++item_count;
            append(records, &record_count, opcode);
            append(records, &record_count, 0);
            break;
        case 1: /* push_tail */
            if (arg1 < MIN_VALUE || arg1 > MAX_VALUE || arg2 != 0 || item_count >= 32u) return -1;
            items[head + item_count++] = arg1;
            append(records, &record_count, opcode);
            append(records, &record_count, 0);
            break;
        case 2: /* pop_head */
            if (arg1 != 0 || arg2 != 0) return -1;
            append(records, &record_count, opcode);
            if (item_count == 0u) append(records, &record_count, 0);
            else {
                append(records, &record_count, 1);
                append(records, &record_count, items[head++]);
                --item_count;
            }
            break;
        case 3: /* pop_tail */
            if (arg1 != 0 || arg2 != 0) return -1;
            append(records, &record_count, opcode);
            if (item_count == 0u) append(records, &record_count, 0);
            else {
                append(records, &record_count, 1);
                append(records, &record_count, items[head + --item_count]);
            }
            break;
        case 4: /* get_head */
        case 5: /* get_tail */
            if (arg1 != 0 || arg2 != 0) return -1;
            append(records, &record_count, opcode);
            if (item_count == 0u) append(records, &record_count, 0);
            else {
                append(records, &record_count, 1);
                append(records, &record_count, opcode == 4 ? items[head] : items[head + item_count - 1u]);
            }
            break;
        case 6: /* get */
            if (arg2 != 0 || arg1 < 1 || (uint64_t)arg1 > item_count) return -1;
            append(records, &record_count, opcode);
            append(records, &record_count, 1);
            append(records, &record_count, items[head + (size_t)arg1 - 1u]);
            break;
        case 7: /* set */
            if (arg1 < 1 || (uint64_t)arg1 > item_count || arg2 < MIN_VALUE || arg2 > MAX_VALUE) return -1;
            items[head + (size_t)arg1 - 1u] = arg2;
            append(records, &record_count, opcode);
            append(records, &record_count, 0);
            break;
        case 8: /* in_bounds */
            if (arg1 < -1 || arg1 > 33 || arg2 != 0) return -1;
            append(records, &record_count, opcode);
            append(records, &record_count, 1);
            append(records, &record_count, arg1 >= 1 && (uint64_t)arg1 <= item_count ? 1 : 0);
            break;
        case 9: /* len */
            if (arg1 != 0 || arg2 != 0) return -1;
            append(records, &record_count, opcode);
            append(records, &record_count, 1);
            append(records, &record_count, (int64_t)item_count);
            break;
        case 10: /* ipairs */
        case 11: /* rpairs */
            if (arg1 != 0 || arg2 != 0) return -1;
            append(records, &record_count, opcode);
            append(records, &record_count, (int64_t)item_count);
            for (size_t index = 0; index < item_count; ++index) {
                const size_t logical = opcode == 10 ? index + 1u : item_count - index;
                append(records, &record_count, (int64_t)logical);
                append(records, &record_count, items[head + logical - 1u]);
            }
            break;
        default:
            return -1;
        }
    }

    append(records, &record_count, 12);
    append(records, &record_count, (int64_t)item_count);
    for (size_t index = 0; index < item_count; ++index)
        append(records, &record_count, items[head + index]);

    const size_t output_bytes = record_count * 8u;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < record_count; ++index)
        write_i64_le(output, index * 8u, records[index]);
    return (int64_t)output_bytes;
}
