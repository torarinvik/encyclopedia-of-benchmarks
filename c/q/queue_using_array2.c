#include <stddef.h>
#include <stdint.h>

#define MAX_Q 256
#define MAX_INPUT_LENGTH 513
#define VALUE_LIMIT INT64_C(1000000)
#define VALUE_OFFSET INT64_C(1000001)
#define HASH_MULTIPLIER INT64_C(1000003)
#define HASH_MODULUS INT64_C(1000000007)

int64_t queue_using_array2(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t qv = packed[0];
    if (qv < 0 || qv > MAX_Q || length != 1 + (size_t)qv * 2) return -1;
    const size_t q = (size_t)qv;
    for (size_t i = 0; i < q; ++i) {
        const int64_t op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 1) { if (value < -VALUE_LIMIT || value > VALUE_LIMIT) return -1; }
        else if (op == 2 || op == 3) { if (value != 0) return -1; }
        else return -1;
    }

    int64_t values[10] = {0};
    size_t count = 0;
    int64_t hash = 0;
    for (size_t i = 0; i < q; ++i) {
        const int64_t op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 1) {
            if (count < 10) values[count++] = value;
        } else if (op == 2 && count > 0) {
            for (size_t j = 1; j < count; ++j) values[j - 1] = values[j];
            --count;
        }

        hash = (hash * HASH_MULTIPLIER + op) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + (int64_t)count) % HASH_MODULUS;
        for (size_t j = 0; j < count; ++j)
            hash = (hash * HASH_MULTIPLIER + values[j] + VALUE_OFFSET) % HASH_MODULUS;
    }
    return hash;
}
