#include <stddef.h>
#include <stdint.h>

#define MAX_COMPONENT INT64_C(100000)
#define OUTPUT_BYTES 16

static void store_i64_le(uint8_t *output, size_t position, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
    }
}

int64_t complex_arithmetic(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 5) return -1;
    int64_t operation = input[0];
    int64_t ar = input[1], ai = input[2], br = input[3], bi = input[4];
    if (operation < 0 || operation > 5 || ar < -MAX_COMPONENT || ar > MAX_COMPONENT ||
        ai < -MAX_COMPONENT || ai > MAX_COMPONENT || br < -MAX_COMPONENT ||
        br > MAX_COMPONENT || bi < -MAX_COMPONENT || bi > MAX_COMPONENT) return -1;

    int64_t real_result = 0, imaginary_result = 0;
    if (operation == 0) {
        real_result = ar + br;
        imaginary_result = ai + bi;
    } else if (operation == 1) {
        real_result = ar - br;
        imaginary_result = ai - bi;
    } else if (operation == 2) {
        real_result = ar * br - ai * bi;
        imaginary_result = ar * bi + ai * br;
    } else if (operation == 3) {
        int64_t denominator = br * br + bi * bi;
        if (denominator == 0) return -1;
        int64_t real_numerator = ar * br + ai * bi;
        int64_t imaginary_numerator = ai * br - ar * bi;
        if (real_numerator % denominator != 0 || imaginary_numerator % denominator != 0) return -1;
        real_result = real_numerator / denominator;
        imaginary_result = imaginary_numerator / denominator;
    } else if (operation == 4) {
        real_result = ar;
        imaginary_result = -ai;
    } else {
        real_result = (ar == br && ai == bi) ? 1 : 0;
    }

    if (output_capacity < OUTPUT_BYTES || output == NULL) return -2;
    store_i64_le(output, 0, real_result);
    store_i64_le(output, 8, imaginary_result);
    return 2;
}
