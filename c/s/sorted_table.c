#include <stddef.h>
#include <stdint.h>

#define MAX_INITIAL_KEYS 128u
#define MAX_OPERATIONS 256u
#define MAX_SIZE 256u
#define MAX_PARSEABLE_INPUT_LENGTH 899u
#define MIN_KEY INT64_C(-1000000)
#define MAX_KEY INT64_C(1000000)
#define KEY_OFFSET INT64_C(1000001)
#define HASH_MODULUS INT64_C(1000000007)

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

static size_t upper_bound_i64(const int64_t *values, size_t size, int64_t target)
{
    size_t left = 0;
    size_t right = size;
    while (left < right) {
        const size_t middle = left + (right - left) / 2u;
        if (values[middle] <= target) left = middle + 1u;
        else right = middle;
    }
    return left;
}

static int64_t key_code(int64_t key) { return key + KEY_OFFSET; }

static int64_t sequence_code(const int64_t *values, size_t first, size_t last, int descending)
{
    const size_t count = last - first;
    int64_t hash = 0;
    if (descending) {
        while (last > first) {
            --last;
            hash = (31 * hash + key_code(values[last])) % HASH_MODULUS;
        }
    } else {
        for (size_t index = first; index < last; ++index)
            hash = (31 * hash + key_code(values[index])) % HASH_MODULUS;
    }
    return (int64_t)count * HASH_MODULUS + hash;
}

int64_t sorted_table_benchmark(const int64_t *input, size_t length)
{
    if (length > MAX_PARSEABLE_INPUT_LENGTH || (length > 0u && input == NULL) || length < 2u) return -1;
    if (input[0] < 0 || input[0] > (int64_t)MAX_INITIAL_KEYS) return -1;
    const size_t initial_count = (size_t)input[0];
    const size_t operation_count_index = initial_count + 1u;
    if (operation_count_index >= length) return -1;
    const int64_t operation_count_value = input[operation_count_index];
    if (operation_count_value < 0 || operation_count_value > (int64_t)MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;
    const size_t operations_start = operation_count_index + 1u;
    if (length != operations_start + 3u * operation_count) return -1;

    int64_t items[MAX_SIZE];
    for (size_t index = 0; index < initial_count; ++index) {
        const int64_t key = input[index + 1u];
        if (key < MIN_KEY || key > MAX_KEY || (index > 0u && items[index - 1u] >= key)) return -1;
        items[index] = key;
    }
    size_t size = initial_count;
    int64_t checksum = 0;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t offset = operations_start + 3u * operation;
        const int64_t opcode = input[offset];
        const int64_t a = input[offset + 1u];
        const int64_t b = input[offset + 2u];
        int has_observation = 1;
        int64_t observed = 0;
        size_t position = 0;

        if (opcode == 0 || opcode == 1 || opcode == 4 || opcode == 5 || opcode == 7) {
            if (b != 0 || a < MIN_KEY || a > MAX_KEY) return -1;
            position = lower_bound_i64(items, size, a);
            const int found = position < size && items[position] == a;
            if (opcode == 0) observed = found ? key_code(a) : 0;
            else if (opcode == 1) observed = found ? 1 : 0;
            else if (opcode == 4) {
                if (found) ++position;
                if (position < size) observed = key_code(items[position]);
            } else if (opcode == 5) {
                if (position > 0u) observed = key_code(items[position - 1u]);
            } else if (found) {
                observed = key_code(a);
                for (size_t index = position; index + 1u < size; ++index) items[index] = items[index + 1u];
                --size;
            }
        } else if (opcode == 2 || opcode == 3) {
            if (a != 0 || b != 0) return -1;
            if (size > 0u) observed = key_code(items[opcode == 2 ? 0u : size - 1u]);
        } else if (opcode == 6) {
            if (a < MIN_KEY || a > MAX_KEY || (b != 0 && b != 1)) return -1;
            position = lower_bound_i64(items, size, a);
            const int found = position < size && items[position] == a;
            if (found) observed = key_code(a);
            else {
                if (size >= MAX_SIZE) return -1;
                for (size_t index = size; index > position; --index) items[index] = items[index - 1u];
                items[position] = a;
                ++size;
            }
        } else if (opcode == 8 || opcode == 9) {
            if (a < MIN_KEY || a > MAX_KEY || b < MIN_KEY || b > MAX_KEY) return -1;
            if (a <= b) {
                const size_t first = lower_bound_i64(items, size, a);
                const size_t last = upper_bound_i64(items, size, b);
                observed = sequence_code(items, first, last, opcode == 9);
            }
        } else if (opcode == 10 || opcode == 11) {
            if (a != 0 || b != 0) return -1;
            observed = sequence_code(items, 0u, size, opcode == 11);
        } else if (opcode == 12) {
            if (a != 0 || b != 0) return -1;
            observed = size == 0u ? 1 : 0;
        } else if (opcode == 13) {
            if (a != 0 || b != 0) return -1;
            size = 0;
            has_observation = 0;
        } else {
            return -1;
        }

        if (has_observation)
            checksum += (int64_t)(operation + 1u) * (observed + 1);
    }

    for (size_t index = 0; index < size; ++index)
        checksum += (int64_t)(operation_count + index + 1u) * key_code(items[index]);
    return checksum;
}
