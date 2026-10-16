#include <stddef.h>
#include <stdint.h>

#define MAX_Q 256
#define MAX_INPUT_LENGTH 513
#define VALUE_LIMIT INT64_C(1000000)
#define VALUE_OFFSET INT64_C(1000001)
#define HASH_MULTIPLIER INT64_C(1000003)
#define HASH_MODULUS INT64_C(1000000007)

int64_t ring_buffer(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t qv = packed[0];
    if (qv < 0 || qv > MAX_Q || length != 1 + (size_t)qv * 2) return -1;
    const size_t q = (size_t)qv;
    for (size_t i = 0; i < q; ++i) {
        const int64_t op = packed[1 + i * 2], payload = packed[2 + i * 2];
        if (op == 0) { if (payload < -VALUE_LIMIT || payload > VALUE_LIMIT) return -1; }
        else if (op == 4) { if (payload < 0 || payload > VALUE_LIMIT) return -1; }
        else if (op >= 1 && op <= 3) { if (payload != 0) return -1; }
        else if (op >= 5 && op <= 9) { if (payload != 0) return -1; }
        else return -1;
    }

    int64_t values[8] = {0};
    size_t head = 0, tail = 0, count = 0;
    int64_t hash = 0;
    for (size_t i = 0; i < q; ++i) {
        const int64_t op = packed[1 + i * 2], payload = packed[2 + i * 2];
        int64_t status = 0, result = 0;
        if (op == 0) {
            if (count == 8) status = 1;
            else { values[tail] = payload; tail = (tail + 1) % 8; ++count; }
        } else if (op == 1) {
            if (count == 0) status = 2;
            else { result = values[head]; head = (head + 1) % 8; --count; }
        } else if (op == 2) {
            if (count == 0) status = 2;
            else result = values[head];
        } else if (op == 3) {
            if (count == 0) status = 2;
            else result = values[(tail + 7) % 8];
        } else if (op == 4) {
            if (payload >= (int64_t)count) status = 3;
            else result = values[(head + (size_t)payload) % 8];
        } else if (op == 5) {
            head = tail = count = 0;
        } else if (op == 6) result = (int64_t)count;
        else if (op == 7) result = 8 - (int64_t)count;
        else if (op == 8) result = count == 0;
        else result = count == 8;

        hash = (hash * HASH_MULTIPLIER + op) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + status) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + result + VALUE_OFFSET) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + (int64_t)count) % HASH_MODULUS;
        for (size_t j = 0; j < count; ++j) {
            const size_t position = (head + j) % 8;
            hash = (hash * HASH_MULTIPLIER + values[position] + VALUE_OFFSET) % HASH_MODULUS;
        }
    }
    return hash;
}
