#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_P 5
#define MAX_PAIRS 10

static void put_f64_le(uint8_t *out, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t b = 0; b < 8; ++b) out[offset + b] = (uint8_t)(bits >> (8 * b));
}
static void put_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[offset + b] = (uint8_t)(bits >> (8 * b));
}

int64_t correlation_matrix_analysis(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 22 || input[0] != 4 || input[1] < 2 || input[1] > MAX_P) return -1;
    const size_t p = (size_t)input[1];
    if (length != 2 + 4 * p) return -1;
    for (size_t i = 0; i < 4 * p; ++i) if (input[2 + i] < -1000 || input[2 + i] > 1000) return -1;
    for (size_t col = 0; col < p; ++col) {
        const int64_t first = input[2 + col];
        int varying = 0;
        for (size_t row = 1; row < 4; ++row) if (input[2 + row * p + col] != first) varying = 1;
        if (!varying) return -1;
    }
    const size_t output_bytes = 32 * p * p + 48;
    if (output == NULL || capacity < output_bytes) return -2;

    double means[MAX_P] = {0}, correlation[MAX_P * MAX_P], raw[MAX_P * MAX_P], bonf[MAX_P * MAX_P], fdr[MAX_P * MAX_P];
    for (size_t col = 0; col < p; ++col) {
        for (size_t row = 0; row < 4; ++row) means[col] += (double)input[2 + row * p + col];
        means[col] /= 4.0;
    }
    for (size_t i = 0; i < p * p; ++i) { correlation[i] = 0.0; raw[i] = 1.0; bonf[i] = 1.0; fdr[i] = 1.0; }
    for (size_t i = 0; i < p; ++i) correlation[i * p + i] = 1.0;

    size_t pair_i[MAX_PAIRS], pair_j[MAX_PAIRS], pair_count = 0;
    double pair_p[MAX_PAIRS];
    for (size_t j = 1; j < p; ++j) for (size_t i = 0; i < j; ++i) {
        double cross = 0.0, sum_i = 0.0, sum_j = 0.0;
        for (size_t row = 0; row < 4; ++row) {
            const double dx = (double)input[2 + row * p + i] - means[i];
            const double dy = (double)input[2 + row * p + j] - means[j];
            cross += dx * dy; sum_i += dx * dx; sum_j += dy * dy;
        }
        const double r = cross / sqrt(sum_i * sum_j);
        const double pv = 1.0 - fabs(r);
        correlation[i * p + j] = correlation[j * p + i] = r;
        raw[i * p + j] = raw[j * p + i] = pv;
        pair_i[pair_count] = i; pair_j[pair_count] = j; pair_p[pair_count++] = pv;
    }
    for (size_t k = 0; k < pair_count; ++k) {
        const double adjusted = fmin(1.0, pair_p[k] * (double)pair_count);
        const size_t i = pair_i[k], j = pair_j[k]; bonf[i * p + j] = bonf[j * p + i] = adjusted;
    }
    size_t order[MAX_PAIRS];
    for (size_t k = 0; k < pair_count; ++k) order[k] = k;
    for (size_t k = 1; k < pair_count; ++k) {
        const size_t value = order[k]; size_t at = k;
        while (at > 0 && pair_p[order[at - 1]] > pair_p[value]) { order[at] = order[at - 1]; --at; }
        order[at] = value;
    }
    double running = 1.0;
    for (size_t pos = pair_count; pos-- > 0;) {
        double adjusted = pair_p[order[pos]] * (double)pair_count / (double)(pos + 1);
        if (adjusted > 1.0) adjusted = 1.0;
        if (adjusted < running) running = adjusted;
        const size_t k = order[pos], i = pair_i[k], j = pair_j[k];
        fdr[i * p + j] = fdr[j * p + i] = running;
    }
    int64_t sig_raw = 0, sig_bonf = 0, sig_fdr = 0;
    for (size_t k = 0; k < pair_count; ++k) {
        if (pair_p[k] < 0.05) ++sig_raw;
        if (bonf[pair_i[k] * p + pair_j[k]] < 0.05) ++sig_bonf;
        if (fdr[pair_i[k] * p + pair_j[k]] < 0.05) ++sig_fdr;
    }
    size_t offset = 0;
    const double *matrices[4] = {correlation, raw, bonf, fdr};
    for (size_t matrix = 0; matrix < 4; ++matrix) for (size_t i = 0; i < p * p; ++i) { put_f64_le(output, offset, matrices[matrix][i]); offset += 8; }
    const int64_t summary[6] = {4, (int64_t)p, 0, sig_raw, sig_bonf, sig_fdr};
    for (size_t i = 0; i < 6; ++i) { put_i64_le(output, offset, summary[i]); offset += 8; }
    return (int64_t)offset;
}
