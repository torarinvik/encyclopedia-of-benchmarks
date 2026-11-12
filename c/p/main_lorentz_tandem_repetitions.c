#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { ML_MAX_N = 24, ML_MAX_REPETITIONS = ML_MAX_N * ML_MAX_N / 4,
       ML_INPUT_MAX = ML_MAX_N + 1, ML_Z_MAX = 2 * ML_MAX_N + 1 };

static size_t ml_min(size_t a, size_t b) { return a < b ? a : b; }
static size_t ml_max(size_t a, size_t b) { return a > b ? a : b; }

static void ml_z_values(const int64_t *sequence, size_t length, size_t z[ML_Z_MAX]) {
    size_t left = 0, right = 0;
    bool has_box = false;
    for (size_t i = 0; i < length; ++i) z[i] = 0;
    for (size_t i = 1; i < length; ++i) {
        if (has_box && i <= right) {
            size_t copied = right - i + 1;
            size_t prior = z[i - left];
            z[i] = prior < copied ? prior : copied;
        }
        while (i + z[i] < length && sequence[z[i]] == sequence[i + z[i]]) ++z[i];
        if (!has_box || i + z[i] - 1 > right) {
            left = i;
            right = i + z[i] - 1;
            has_box = true;
        }
    }
}

static size_t ml_z_at(const size_t *z, size_t length, size_t index) {
    return index < length ? z[index] : 0;
}

static void ml_divide(const int64_t *symbols, size_t offset, size_t length,
                      bool marked[ML_MAX_N][ML_MAX_N + 1]) {
    if (length <= 1) return;
    const size_t left_size = length / 2;
    const size_t right_size = length - left_size;
    const size_t middle = offset + left_size;
    int64_t buffer[ML_Z_MAX];
    size_t z[ML_Z_MAX];
    size_t before[ML_MAX_N] = {0}, after[ML_MAX_N] = {0};

    ml_divide(symbols, offset, left_size, marked);
    ml_divide(symbols, middle, right_size, marked);

    for (size_t i = 0; i < left_size; ++i) buffer[i] = symbols[middle - 1 - i];
    ml_z_values(buffer, left_size, z);
    for (size_t center = 0; center < left_size; ++center)
        before[center] = ml_z_at(z, left_size, left_size - center);

    size_t used = 0;
    for (size_t i = 0; i < right_size; ++i) buffer[used++] = symbols[middle + i];
    buffer[used++] = -1;
    for (size_t i = 0; i < left_size; ++i) buffer[used++] = symbols[offset + i];
    ml_z_values(buffer, used, z);
    for (size_t center = 0; center < left_size; ++center)
        after[center] = ml_z_at(z, used, right_size + 1 + center);

    for (size_t i = 0; i < left_size; ++i) buffer[i] = symbols[middle - 1 - i];
    used = left_size;
    buffer[used++] = -1;
    for (size_t i = 0; i < right_size; ++i) buffer[used++] = symbols[offset + length - 1 - i];
    ml_z_values(buffer, used, z);
    for (size_t d = 0; d < right_size; ++d)
        before[left_size + d] = ml_z_at(z, used, left_size + 1 + right_size - 1 - d);

    for (size_t i = 0; i < right_size; ++i) buffer[i] = symbols[middle + i];
    ml_z_values(buffer, right_size, z);
    for (size_t d = 0; d < right_size; ++d)
        after[left_size + d] = ml_z_at(z, right_size, d + 1);

    for (size_t center = 0; center < length; ++center) {
        const bool left_biased = center < left_size;
        const size_t half = left_biased ? left_size - center : center - left_size + 1;
        if (before[center] + after[center] < half) continue;
        const size_t low = ml_max(1, half > after[center] ? half - after[center] : 0);
        const size_t high = ml_min(half, before[center]);
        for (size_t first_half = low; first_half <= high; ++first_half) {
            if (left_biased && first_half == half) continue;
            const size_t start = left_biased
                ? center - first_half
                : center - half - first_half + 1;
            marked[offset + start][half] = true;
        }
    }
}

static void ml_store(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t main_lorentz_tandem_repetitions(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > ML_INPUT_MAX) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > ML_MAX_N || length != (size_t)n_value + 1) return -1;
    const size_t n = (size_t)n_value;
    int64_t symbols[ML_MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        symbols[i] = input[i + 1];
        if (symbols[i] < 0 || symbols[i] > 255) return -1;
    }

    bool marked[ML_MAX_N][ML_MAX_N + 1] = {{false}};
    ml_divide(symbols, 0, n, marked);
    int64_t codes[ML_MAX_REPETITIONS] = {0};
    size_t count = 0;
    for (size_t start = 0; start < n; ++start) {
        for (size_t half = 1; half <= n / 2; ++half) {
            if (start + 2 * half <= n && marked[start][half])
                codes[count++] = (int64_t)(start * 32 + half);
        }
    }
    const size_t required = 8 * (count + 1);
    if (output == NULL || capacity < required) return -2;
    ml_store(output, 0, (int64_t)count);
    for (size_t i = 0; i < count; ++i) ml_store(output, 8 * (i + 1), codes[i]);
    return (int64_t)required;
}
