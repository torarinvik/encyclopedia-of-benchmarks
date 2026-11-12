/* Clean-room bounded one-step gated graph-message update. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t graphai_ggnn_message_update(const double *input, size_t length,
                                    double *output, size_t capacity) {
    enum { N = 8, M = 24, D = 4, MAX_VALID = 452, MAX_PARSEABLE = 453 };
    if (input == NULL || length < 3 || length > MAX_PARSEABLE) return -1;
    for (size_t q = 0; q < length; ++q) if (!isfinite(input[q])) return -1;
    double nv = input[0], mv = input[1], dv = input[2];
    if (trunc(nv) != nv || trunc(mv) != mv || trunc(dv) != dv ||
        nv < 1 || nv > N || mv < 0 || mv > M || dv < 1 || dv > D) return -1;
    size_t n = (size_t)nv, m = (size_t)mv, d = (size_t)dv;
    size_t expected = 4 + n + m + n * d + 6 * n * n;
    if (length != expected) return -1;
    size_t row_at = 3, col_at = row_at + n + 1, h_at = col_at + m;
    size_t wz_at = h_at + n * d, wr_at = wz_at + n * n;
    size_t wc_at = wr_at + n * n, uz_at = wc_at + n * n;
    size_t ur_at = uz_at + n * n, uc_at = ur_at + n * n;
    if (input[row_at] != 0.0 || input[col_at - 1] != (double)m) return -1;
    size_t row[N + 1] = {0}, col[M] = {0};
    for (size_t i = 0; i <= n; ++i) {
        double x = input[row_at + i];
        if (trunc(x) != x || x < 0 || x > (double)m) return -1;
        row[i] = (size_t)x;
        if (i && row[i] < row[i - 1]) return -1;
    }
    for (size_t e = 0; e < m; ++e) {
        double x = input[col_at + e];
        if (trunc(x) != x || x < 0 || x >= (double)n) return -1;
        col[e] = (size_t)x;
    }
    for (size_t q = h_at; q < wz_at; ++q)
        if (input[q] < -1.0 || input[q] > 1.0) return -1;
    for (size_t q = wz_at; q < length; ++q)
        if (input[q] < -0.25 || input[q] > 0.25) return -1;
    size_t required = n * d;
    if (output == NULL || capacity < required) return -2;
    double aggregate[N * D] = {0}, update[N * D] = {0};
    double reset[N * D] = {0}, candidate[N * D] = {0};
    double staged[N * D] = {0};
    for (size_t v = 0; v < n; ++v)
        for (size_t e = row[v]; e < row[v + 1]; ++e)
            for (size_t f = 0; f < d; ++f)
                aggregate[v * d + f] += input[h_at + col[e] * d + f];
    for (size_t v = 0; v < n; ++v) for (size_t f = 0; f < d; ++f) {
        double uz_sum = 0, ur_sum = 0, wz_sum = 0, wr_sum = 0;
        for (size_t k = 0; k < n; ++k) {
            size_t matrix = v * n + k, feature = k * d + f;
            wz_sum += input[wz_at + matrix] * aggregate[feature];
            wr_sum += input[wr_at + matrix] * aggregate[feature];
            uz_sum += input[uz_at + matrix] * input[h_at + feature];
            ur_sum += input[ur_at + matrix] * input[h_at + feature];
        }
        size_t at = v * d + f;
        update[at] = 1.0 / (1.0 + exp(-(wz_sum + uz_sum)));
        reset[at] = 1.0 / (1.0 + exp(-(wr_sum + ur_sum)));
    }
    for (size_t v = 0; v < n; ++v) for (size_t f = 0; f < d; ++f) {
        double message = 0, gated_state = 0;
        for (size_t k = 0; k < n; ++k) {
            size_t matrix = v * n + k, feature = k * d + f;
            message += input[wc_at + matrix] * aggregate[feature];
            gated_state += input[uc_at + matrix] *
                           (reset[feature] * input[h_at + feature]);
        }
        size_t at = v * d + f;
        candidate[at] = tanh(message + gated_state);
        staged[at] = (1.0 - update[at]) * input[h_at + at] +
                     update[at] * candidate[at];
    }
    for (size_t q = 0; q < required; ++q) output[q] = staged[q];
    return (int64_t)required;
}
