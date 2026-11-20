#include <stddef.h>
#include <stdint.h>

#define MAX_COORDINATE INT64_C(10000)

static int gp_is_rational_prime(int64_t value) {
    if (value < 2) return 0;
    if (value % 2 == 0) return value == 2;
    for (int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

int64_t gaussian_prime_classifier(const int64_t *input, size_t length) {
    if (input == NULL || length < 1U || length > 3U) return -1;
    if (length != 2U) return -1;
    const int64_t real = input[0];
    const int64_t imaginary = input[1];
    if (real < -MAX_COORDINATE || real > MAX_COORDINATE ||
        imaginary < -MAX_COORDINATE || imaginary > MAX_COORDINATE) return -1;
    if (real == 0 && imaginary == 0) return 0;
    if (real == 0 || imaginary == 0) {
        const int64_t axis = real == 0 ? imaginary : real;
        const int64_t rational = axis < 0 ? -axis : axis;
        if (rational % 4 == 3 && gp_is_rational_prime(rational)) return 1;
        return 0;
    }
    const int64_t norm = real * real + imaginary * imaginary;
    return gp_is_rational_prime(norm) ? 1 : 0;
}
