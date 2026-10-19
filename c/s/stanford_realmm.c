/* Port the floating-point matrix multiplication from Stanford RealMM. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { ROWSIZE = 40, CELL_COUNT = ROWSIZE * ROWSIZE, MAX_PASSES = 10, MAX_OUTPUT_BYTES = 140 };

static uint64_t rounded_micro_units(uint64_t bits)
{
    const uint64_t exponent = (bits >> 52) & 0x7ffu;
    uint64_t significand = bits & ((UINT64_C(1) << 52) - 1);
    if (exponent == 0) return 0;
    significand |= UINT64_C(1) << 52;
    const uint64_t shift = 1075u - exponent;
    if (shift >= 74) return 0;
    const uint64_t low_product = (significand & UINT64_C(0xffffffff)) * UINT64_C(1000000);
    const uint64_t high_product = (significand >> 32) * UINT64_C(1000000);
    const uint64_t middle = (low_product >> 32) + (high_product & UINT64_C(0xffffffff));
    const uint64_t limb0 = low_product & UINT64_C(0xffffffff);
    const uint64_t limb1 = middle & UINT64_C(0xffffffff);
    const uint64_t limb2 = (high_product >> 32) + (middle >> 32);
    uint64_t quotient, half_bit;
    int lower_nonzero;
    if (shift < 64) {
        const uint64_t part = shift - 32;
        quotient = (limb1 >> part) | (limb2 << (32 - part));
        half_bit = (limb1 >> (part - 1)) & 1u;
        lower_nonzero = limb0 != 0 || (limb1 & ((UINT64_C(1) << (part - 1)) - 1)) != 0;
    } else if (shift == 64) {
        quotient = limb2;
        half_bit = limb1 >> 31;
        lower_nonzero = limb0 != 0 || (limb1 & UINT64_C(0x7fffffff)) != 0;
    } else {
        const uint64_t part = shift - 64;
        quotient = limb2 >> part;
        half_bit = (limb2 >> (part - 1)) & 1u;
        lower_nonzero = limb0 != 0 || limb1 != 0 || (limb2 & ((UINT64_C(1) << (part - 1)) - 1)) != 0;
    }
    if (half_bit != 0 && (lower_nonzero || (quotient & 1u) != 0)) ++quotient;
    return quotient;
}

static void append_integer(uint64_t value, uint8_t *buffer, size_t *used)
{
    uint8_t reversed[20];
    size_t count = 0;
    do {
        reversed[count++] = (uint8_t)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) buffer[(*used)++] = reversed[--count];
}

static void append_fixed(double value, uint8_t *buffer, size_t *used)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof bits);
    if ((bits >> 63) != 0) buffer[(*used)++] = '-';
    const uint64_t scaled = rounded_micro_units(bits & UINT64_C(0x7fffffffffffffff));
    append_integer(scaled / UINT64_C(1000000), buffer, used);
    buffer[(*used)++] = '.';
    uint64_t fraction = scaled % UINT64_C(1000000);
    uint64_t place = UINT64_C(100000);
    while (place > 0) {
        buffer[(*used)++] = (uint8_t)('0' + fraction / place);
        fraction %= place;
        place /= 10;
    }
}

int64_t stanford_realmm(int64_t pass_count, uint8_t *output, size_t output_capacity)
{
    if (pass_count < 1 || pass_count > MAX_PASSES) return -1;
    if (output == NULL) return -2;

    double a[CELL_COUNT], b[CELL_COUNT], product[CELL_COUNT];
    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t used = 0;
    for (int64_t pass = 0; pass < pass_count; ++pass) {
        uint32_t seed = 74755;
        for (size_t index = 0; index < CELL_COUNT; ++index) {
            seed = (seed * 1309u + 13849u) & 65535u;
            const int temp = (int)seed;
            const int residue = temp - (temp / 120) * 120 - 60;
            a[index] = (double)residue / 3.0;
        }
        for (size_t index = 0; index < CELL_COUNT; ++index) {
            seed = (seed * 1309u + 13849u) & 65535u;
            const int temp = (int)seed;
            const int residue = temp - (temp / 120) * 120 - 60;
            b[index] = (double)residue / 3.0;
        }

        for (size_t row = 0; row < ROWSIZE; ++row) {
            for (size_t column = 0; column < ROWSIZE; ++column) {
                double sum = 0.0;
                for (size_t inner = 0; inner < ROWSIZE; ++inner)
                    sum = sum + a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column];
                product[row * ROWSIZE + column] = sum;
            }
        }
        append_fixed(product[(size_t)pass * ROWSIZE + (size_t)pass], staged, &used);
        staged[used++] = '\n';
    }

    if (output_capacity < used) return -2;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return (int64_t)used;
}
