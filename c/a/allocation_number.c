#include <stddef.h>
#include <stdint.h>

#define MAX_BYTES UINT64_C(1000000)
#define MAX_PARTITIONS UINT64_C(128)

static int append_u64(uint64_t value, uint8_t *output, size_t capacity, size_t *position)
{
    uint8_t digits[20];
    size_t count = 0;
    do { digits[count++] = (uint8_t)('0' + value % 10); value /= 10; } while (value != 0);
    if (count > capacity - *position) return 0;
    while (count != 0) output[(*position)++] = digits[--count];
    return 1;
}

int64_t allocation_number(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 2 || values[0] < 1 || values[0] > (int64_t)MAX_BYTES ||
        values[1] < 1 || values[1] > (int64_t)MAX_PARTITIONS || values[1] > values[0]) return -1;
    const uint64_t total = (uint64_t)values[0], partitions = (uint64_t)values[1];
    const uint64_t block = total / partitions;
    size_t position = 0;
    for (uint64_t index = 0; index < partitions; ++index) {
        const uint64_t start = index * block + 1;
        const uint64_t end = index + 1 == partitions ? total : (index + 1) * block;
        if (!append_u64(start, output, output_capacity, &position)) return -2;
        if (position >= output_capacity) return -2;
        output[position++] = '-';
        if (!append_u64(end, output, output_capacity, &position)) return -2;
        if (index + 1 != partitions) {
            if (position >= output_capacity) return -2;
            output[position++] = ',';
        }
    }
    return (int64_t)position;
}
