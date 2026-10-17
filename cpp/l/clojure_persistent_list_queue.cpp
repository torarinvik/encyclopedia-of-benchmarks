#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 256
#define MAX_QUEUE_LENGTH 64
#define MAX_VALID_INPUT_LENGTH (1 + 2 * MAX_OPERATIONS)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static void hash_byte(uint64_t *hash, uint8_t byte)
{
    *hash = (*hash ^ byte) * FNV_PRIME;
}

static void hash_u16(uint64_t *hash, uint16_t value)
{
    for (unsigned byte = 0; byte < 2; ++byte) hash_byte(hash, (uint8_t)(value >> (8 * byte)));
}

static void hash_i32(uint64_t *hash, int32_t value)
{
    uint32_t bits = (uint32_t)value;
    for (unsigned byte = 0; byte < 4; ++byte) hash_byte(hash, (uint8_t)(bits >> (8 * byte)));
}

static void hash_i64(uint64_t *hash, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (unsigned byte = 0; byte < 8; ++byte) hash_byte(hash, (uint8_t)(bits >> (8 * byte)));
}

extern "C" int64_t clojure_persistent_list_queue(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;
    const int operation_count = (int)input[0];
    if (length != 1 + (size_t)operation_count * 2 || length > MAX_VALID_INPUT_LENGTH) return -1;

    int32_t newest_first[MAX_QUEUE_LENGTH];
    int queue_size = 0;
    int64_t results[MAX_OPERATIONS];
    uint8_t opcodes[MAX_OPERATIONS];
    for (int operation = 0; operation < operation_count; ++operation) {
        size_t offset = 1 + (size_t)operation * 2;
        int64_t opcode_value = input[offset];
        int64_t argument = input[offset + 1];
        if (opcode_value < 0 || opcode_value > 3) return -1;
        int opcode = (int)opcode_value;
        opcodes[operation] = (uint8_t)opcode;
        if (opcode == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX || queue_size >= MAX_QUEUE_LENGTH) return -1;
            for (int index = queue_size; index > 0; --index) newest_first[index] = newest_first[index - 1];
            newest_first[0] = (int32_t)argument;
            ++queue_size;
            results[operation] = queue_size;
        } else if (opcode == 1) {
            if (argument != 0) return -1;
            if (queue_size > 0) --queue_size;
            results[operation] = queue_size;
        } else if (opcode == 2) {
            if (argument != 0) return -1;
            results[operation] = queue_size == 0 ? INT64_MIN : newest_first[queue_size - 1];
        } else {
            if (argument != 0) return -1;
            results[operation] = queue_size == 0 ? 1 : 0;
        }
    }

    uint64_t hash = FNV_OFFSET;
    hash_u16(&hash, (uint16_t)operation_count);
    for (int operation = 0; operation < operation_count; ++operation) {
        hash_byte(&hash, opcodes[operation]);
        hash_i64(&hash, results[operation]);
    }
    hash_u16(&hash, (uint16_t)queue_size);
    for (int index = queue_size - 1; index >= 0; --index) hash_i32(&hash, newest_first[index]);
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
