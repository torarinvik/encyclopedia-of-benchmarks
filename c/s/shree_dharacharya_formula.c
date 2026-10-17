#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

static void write_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8U * (unsigned)byte));
}

int64_t shree_dharacharya_formula(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity)
{
    if (input == NULL || length != 3) return -1;
    for (size_t index = 0; index < 3; ++index)
        if (input[index] < -1000000 || input[index] > 1000000) return -1;
    if (input[0] == 0) return -1;
    const double a = (double)input[0], b = (double)input[1], c = (double)input[2];
    const double discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) return -1;
    if (output == NULL || capacity < 16) return -2;
    const double root = sqrt(discriminant);
    const double denominator = 2.0 * a;
    const double first = (-b + root) / denominator;
    const double second = (-b - root) / denominator;
    write_f64_le(output, 0, first);
    write_f64_le(output, 8, second);
    return 16;
}
