#include <stddef.h>
#include <stdint.h>

static int64_t falling(int64_t top, size_t k) {
    int64_t product = 1;
    for (size_t i = 0; i < k; ++i) product *= top - (int64_t)i;
    return product;
}

static int64_t gcd_i64(int64_t a, int64_t b) {
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a;
}

int64_t reservoir_sampling_algorithm_x(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 49 || input[0] < 1 || input[0] > 16) return -1;
    size_t n = (size_t)input[0];
    if (input[1] < 1 || input[1] > 8) return -1;
    size_t k = (size_t)input[1];
    if ((k & (k - 1)) != 0 || k > n || length != 2+n+2*(n-k)) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2+i] < -1000000 || input[2+i] > 1000000) return -1;
    for (size_t i = 2+n; i < length; ++i) if (input[i] < 0 || input[i] > 4294967295LL) return -1;
    if (output == NULL || capacity < 8*k) return -2;
    int64_t sample[8];
    for (size_t i = 0; i < k; ++i) sample[i] = input[2+i];
    size_t processed = k, attempt = 0;
    while (processed < n) {
        int64_t draw = input[2+n+2*attempt];
        int64_t slot_draw = input[2+n+2*attempt+1];
        ++attempt;
        int64_t numerator = falling((int64_t)processed, k);
        int64_t denominator = falling((int64_t)processed+1, k);
        int64_t divisor = gcd_i64(numerator, denominator);
        numerator /= divisor; denominator /= divisor;
        size_t max_skip = n-processed-1, selected = 0;
        int found = 0;
        for (size_t skip = 0; skip <= max_skip; ++skip) {
            if (numerator*4294967297LL <= (draw+1)*denominator) { selected = skip; found = 1; break; }
            if (skip < max_skip) {
                int64_t top = (int64_t)(processed+skip+1);
                numerator *= top+1-(int64_t)k;
                denominator *= top+1;
                divisor = gcd_i64(numerator, denominator);
                numerator /= divisor; denominator /= divisor;
            }
        }
        if (!found) break;
        sample[(size_t)(slot_draw % (int64_t)k)] = input[2+processed+selected];
        processed += selected+1;
    }
    for (size_t i = 0; i < k; ++i) {
        uint64_t bits = (uint64_t)sample[i];
        for (size_t j = 0; j < 8; ++j) { output[8*i+j] = (uint8_t)(bits & 255u); bits >>= 8; }
    }
    return (int64_t)(8*k);
}
