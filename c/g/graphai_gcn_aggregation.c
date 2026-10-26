/* Clean-room bounded GCN normalized-neighbor aggregation. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_M 24
#define MAX_D 4
#define MAX_INPUT (4 + 3 * MAX_N + MAX_M + MAX_N * MAX_D)

int64_t graphai_gcn_aggregation(const double *input, size_t length,
                                double *output, size_t capacity) {
    if (!input || length < 7 || length > MAX_INPUT) return -1;
    for (size_t q = 0; q < length; ++q) if (!isfinite(input[q])) return -1;
    double nv = input[0], mv = input[1], dv = input[2];
    if (trunc(nv) != nv || trunc(mv) != mv || trunc(dv) != dv ||
        nv < 1 || nv > MAX_N || mv < 0 || mv > MAX_M || dv < 1 || dv > MAX_D) return -1;
    size_t n = (size_t)nv, m = (size_t)mv, d = (size_t)dv;
    if (length != 4 + 3*n + m + n*d) return -1;
    size_t offsets_at = 3, edges_at = offsets_at + n + 1;
    size_t left_at = edges_at + m, right_at = left_at + n, features_at = right_at + n;
    if (input[offsets_at] != 0 || input[edges_at - 1] != (double)m) return -1;
    size_t rowptr[MAX_N + 1], colind[MAX_M];
    for (size_t i = 0; i <= n; ++i) {
        double value = input[offsets_at + i];
        if (trunc(value) != value || value < 0 || value > m) return -1;
        rowptr[i] = (size_t)value;
        if (i && rowptr[i] < rowptr[i-1]) return -1;
    }
    for (size_t e = 0; e < m; ++e) {
        double value = input[edges_at + e];
        if (trunc(value) != value || value < 0 || value >= n) return -1;
        colind[e] = (size_t)value;
    }
    for (size_t i = 0; i < n; ++i)
        if (input[left_at+i] < -4 || input[left_at+i] > 4 ||
            input[right_at+i] < -4 || input[right_at+i] > 4) return -1;
    for (size_t q = 0; q < n*d; ++q)
        if (input[features_at+q] < -8 || input[features_at+q] > 8) return -1;
    size_t required = n*d;
    if (!output || capacity < required) return -2;
    double staged[MAX_N * MAX_D] = {0};
    for (size_t src = 0; src < n; ++src)
        for (size_t e = rowptr[src]; e < rowptr[src+1]; ++e) {
            size_t dst = colind[e];
            double weight = input[left_at+src] * input[right_at+dst];
            for (size_t k = 0; k < d; ++k)
                staged[src*d+k] += weight * input[features_at+dst*d+k];
        }
    for (size_t q = 0; q < required; ++q) output[q] = staged[q];
    return (int64_t)required;
}
