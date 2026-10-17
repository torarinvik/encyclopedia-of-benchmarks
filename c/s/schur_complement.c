/* Scalar Schur complement for a bounded symmetric 2x2 block. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double schur_complement(const int64_t *values, size_t length) {
    if (values == NULL || length != 6) return INVALID_RESULT;

    const int64_t a00 = values[0];
    const int64_t a01 = values[1];
    const int64_t a11 = values[2];
    const int64_t b0 = values[3];
    const int64_t b1 = values[4];
    const int64_t c00 = values[5];

    if (a00 < -8 || a00 > 8 || a01 < -8 || a01 > 8 ||
            a11 < -8 || a11 > 8 ||
            b0 < -100 || b0 > 100 || b1 < -100 || b1 > 100 ||
            c00 < -100 || c00 > 100)
        return INVALID_RESULT;

    const int64_t determinant = a00 * a11 - a01 * a01;
    if (determinant == 0) return INVALID_RESULT;

    const double inverse00 = (double)a11 / (double)determinant;
    const double inverse01 = -(double)a01 / (double)determinant;
    const double inverse10 = inverse01;
    const double inverse11 = (double)a00 / (double)determinant;

    /* Match the source's left-to-right B.T @ inv(A) @ B evaluation. */
    const double left0 = (double)b0 * inverse00 + (double)b1 * inverse10;
    const double left1 = (double)b0 * inverse01 + (double)b1 * inverse11;
    const double quadratic = left0 * (double)b0 + left1 * (double)b1;
    return (double)c00 - quadratic;
}
