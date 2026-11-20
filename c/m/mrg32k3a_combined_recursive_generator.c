#include <stddef.h>
#include <stdint.h>

enum { MAX_COUNT = 64 };
static const int64_t M1 = INT64_C(4294967087);
static const int64_t M2 = INT64_C(4294944443);

static int64_t residue(int64_t value, int64_t modulus) {
    int64_t result = value % modulus;
    return result < 0 ? result + modulus : result;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t mrg32k3a_combined_recursive_generator(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 7) return -1;
    for (size_t i = 0; i < 3; ++i)
        if (input[i] < 0 || input[i] >= M1) return -1;
    for (size_t i = 3; i < 6; ++i)
        if (input[i] < 0 || input[i] >= M2) return -1;
    if ((input[0] | input[1] | input[2]) == 0 ||
        (input[3] | input[4] | input[5]) == 0 ||
        input[6] < 0 || input[6] > MAX_COUNT) return -1;

    const size_t count = (size_t)input[6];
    const size_t required = count * 8;
    if (capacity < required || (required != 0 && output == NULL)) return -2;
    if (count == 0) return 0;

    int64_t x1[3] = {input[0], input[1], input[2]};
    int64_t x2[3] = {input[3], input[4], input[5]};
    for (size_t step = 0; step < count; ++step) {
        const int64_t next1 = residue(INT64_C(1403580) * x1[1] -
                                      INT64_C(810728) * x1[0], M1);
        const int64_t next2 = residue(INT64_C(527612) * x2[2] -
                                      INT64_C(1370589) * x2[0], M2);
        x1[0] = x1[1]; x1[1] = x1[2]; x1[2] = next1;
        x2[0] = x2[1]; x2[1] = x2[2]; x2[2] = next2;
        int64_t z = next1 - next2;
        if (z < 0) z += M1;
        put_i64_le(output, step * 8, z);
    }
    return (int64_t)required;
}
