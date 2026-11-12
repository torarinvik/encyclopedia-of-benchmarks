#include <stddef.h>
#include <stdint.h>

typedef struct {
    int64_t lower_numerator;
    int64_t lower_denominator;
    int64_t upper_numerator;
    int64_t upper_denominator;
} rational_bounds;

static int64_t gcd_positive(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static rational_bounds bounded_neighbors(int64_t limit, int64_t x, int64_t y) {
    const int64_t divisor = gcd_positive(x, y);
    const int64_t reduced_x = x / divisor;
    const int64_t reduced_y = y / divisor;
    if (reduced_x <= limit && reduced_y <= limit) {
        return (rational_bounds){reduced_x, reduced_y, reduced_x, reduced_y};
    }

    int64_t a = 0, b = 1;
    int64_t c = 1, d = 0;
    while (1) {
        const int64_t middle_numerator = a + c;
        const int64_t middle_denominator = b + d;
        if (middle_numerator > limit || middle_denominator > limit) break;

        const int64_t target_side = middle_numerator * y;
        const int64_t middle_side = middle_denominator * x;
        if (target_side == middle_side) {
            return (rational_bounds){middle_numerator, middle_denominator,
                                     middle_numerator, middle_denominator};
        }

        if (target_side < middle_side) {
            const int64_t lower_gap = b * x - a * y;
            const int64_t upper_gap = c * y - d * x;
            int64_t step = lower_gap / upper_gap;
            const int64_t numerator_cap = (limit - a) / c;
            if (step > numerator_cap) step = numerator_cap;
            if (d > 0) {
                const int64_t denominator_cap = (limit - b) / d;
                if (step > denominator_cap) step = denominator_cap;
            }
            a += step * c;
            b += step * d;
        } else {
            const int64_t upper_gap = c * y - d * x;
            const int64_t lower_gap = b * x - a * y;
            int64_t step = upper_gap / lower_gap;
            if (a > 0) {
                const int64_t numerator_cap = (limit - c) / a;
                if (step > numerator_cap) step = numerator_cap;
            }
            const int64_t denominator_cap = (limit - d) / b;
            if (step > denominator_cap) step = denominator_cap;
            c += step * a;
            d += step * b;
        }
    }
    return (rational_bounds){a, b, c, d};
}

static void store_i64_le(uint8_t* output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)((bits >> (byte * 8)) & UINT64_C(0xff));
    }
}

int64_t rational_approximation(const int64_t* values, size_t length,
                               uint8_t* output, size_t capacity) {
    if (values == NULL || length != 3) return -1;
    const int64_t limit = values[0];
    const int64_t x = values[1];
    const int64_t y = values[2];
    if (limit < 1 || limit > INT64_C(1000000000)
        || x < 1 || x > INT64_C(1000000000)
        || y < 1 || y > INT64_C(1000000000)) return -1;
    if (output == NULL || capacity < 32) return -2;

    const rational_bounds bounds = bounded_neighbors(limit, x, y);
    store_i64_le(output, 0, bounds.lower_numerator);
    store_i64_le(output, 8, bounds.lower_denominator);
    store_i64_le(output, 16, bounds.upper_numerator);
    store_i64_le(output, 24, bounds.upper_denominator);
    return 32;
}
