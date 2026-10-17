#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_LENGTH 1025u
#define MAX_OPERATIONS 512u
#define MAX_SIZE 256u
#define MAX_VALUE INT64_C(1000000)
#define CHECKSUM_OFFSET INT64_C(1000000)

static size_t lower_bound_i64(const int64_t *values, size_t size, int64_t target)
{
    size_t left = 0;
    size_t right = size;
    while (left < right) {
        const size_t middle = left + (right - left) / 2u;
        if (values[middle] < target) left = middle + 1u;
        else right = middle;
    }
    return left;
}

int64_t sorted_list_benchmark(const int64_t *input, size_t length)
{
    if (length > MAX_PARSEABLE_INPUT_LENGTH || (length > 0u && input == NULL) || (length & 1u) != 0u)
        return -1;
    const size_t operation_count = length / 2u;
    if (operation_count > MAX_OPERATIONS) return -1;

    int64_t items[MAX_SIZE];
    size_t size = 0;
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = input[2u * operation];
        const int64_t payload = input[2u * operation + 1u];
        int64_t observed = 0;
        int has_observation = 1;

        if (opcode == 0) {
            if (payload < 0 || payload > MAX_VALUE || size >= MAX_SIZE) return -1;
            size_t position = lower_bound_i64(items, size, payload);
            for (size_t index = size; index > position; --index) items[index] = items[index - 1u];
            items[position] = payload;
            ++size;
            has_observation = 0;
        } else if (opcode == 1 || opcode == 2) {
            if (payload < 0 || payload > MAX_VALUE) return -1;
            const size_t position = lower_bound_i64(items, size, payload);
            const int found = position < size && items[position] == payload;
            observed = found ? 1 : 0;
            if (opcode == 2 && found) {
                for (size_t index = position; index + 1u < size; ++index) items[index] = items[index + 1u];
                --size;
            }
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            observed = (int64_t)size;
        } else if (opcode == 4) {
            if (payload < 0 || (uint64_t)payload >= size) return -1;
            observed = items[(size_t)payload];
        } else if (opcode == 5) {
            if (payload != 0) return -1;
            size = 0;
            has_observation = 0;
        } else {
            return -1;
        }

        if (has_observation)
            checksum += (int64_t)(operation + 1u) * (observed + CHECKSUM_OFFSET);
    }

    for (size_t index = 0; index < size; ++index)
        checksum += (int64_t)(operation_count + index + 1u) * (items[index] + CHECKSUM_OFFSET);
    return checksum;
}
