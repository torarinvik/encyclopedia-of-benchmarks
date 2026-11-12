#include <stddef.h>
#include <stdint.h>

#define MAX_T 8
#define MAX_COMPONENT INT64_C(1000000)

static int64_t nearest_quotient(int64_t numerator, int64_t denominator) {
    const int64_t sign = numerator < 0 ? -1 : 1;
    const int64_t magnitude = numerator < 0 ? -numerator : numerator;
    int64_t quotient = magnitude / denominator;
    const int64_t remainder = magnitude % denominator;
    if (2 * remainder >= denominator) ++quotient;
    return sign * quotient;
}

static void gaussian_gcd(int64_t ar, int64_t ai, int64_t br, int64_t bi,
                         int64_t *result_real, int64_t *result_imaginary) {
    while (br != 0 || bi != 0) {
        const int64_t denominator = br * br + bi * bi;
        const int64_t qr = nearest_quotient(ar * br + ai * bi, denominator);
        const int64_t qi = nearest_quotient(ai * br - ar * bi, denominator);
        const int64_t rr = ar - (qr * br - qi * bi);
        const int64_t ri = ai - (qr * bi + qi * br);
        ar = br;
        ai = bi;
        br = rr;
        bi = ri;
    }

    if (ar != 0 || ai != 0) {
        for (int rotation = 0; rotation < 4 && !(ar > 0 && ai >= 0); ++rotation) {
            const int64_t old_real = ar;
            ar = -ai;
            ai = old_real;
        }
    }
    *result_real = ar;
    *result_imaginary = ai;
}

static void write_u32(uint8_t *output, size_t offset, uint32_t value) {
    output[offset] = (uint8_t)value;
    output[offset + 1] = (uint8_t)(value >> 8);
    output[offset + 2] = (uint8_t)(value >> 16);
    output[offset + 3] = (uint8_t)(value >> 24);
}

int64_t gcd_of_gaussian_integers(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > 1 + 4 * MAX_T) return -1;
    const int64_t t64 = input[0];
    if (t64 < 1 || t64 > MAX_T) return -1;
    const size_t t = (size_t)t64;
    if (length != 1 + 4 * t) return -1;

    int64_t values[4 * MAX_T] = {0};
    for (size_t i = 0; i < 4 * t; ++i) {
        if (input[i + 1] < -MAX_COMPONENT || input[i + 1] > MAX_COMPONENT) return -1;
        values[i] = input[i + 1];
    }
    const size_t required = 8 * t;
    if (output == NULL || capacity < required) return -2;

    for (size_t test = 0; test < t; ++test) {
        int64_t real = 0, imaginary = 0;
        gaussian_gcd(values[4 * test], values[4 * test + 1],
                     values[4 * test + 2], values[4 * test + 3],
                     &real, &imaginary);
        write_u32(output, 8 * test, (uint32_t)real);
        write_u32(output, 8 * test + 4, (uint32_t)imaginary);
    }
    return (int64_t)required;
}
