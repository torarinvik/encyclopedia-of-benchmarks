/****
    Copyright (C) 1996 McGill University.
    Copyright (C) 1996 McCAT System Group.
    Copyright (C) 1996 ACAPS Benchmark Administrator
                       benadmin@acaps.cs.mcgill.ca

    This program is free software; you can redistribute it and/or modify
    it provided this copyright notice is maintained.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
****/
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_N 3
#define MAX_N 8
#define MAX_INPUT (2 + MAX_N * MAX_N)
#define MAX_OUTPUT (MAX_N * 4)
#define INPUT_SCALE 1000000.0
#define OUTPUT_SCALE 1000.0
#define QR_EPSILON 1.0e-10
#define MAX_QR_STEPS 4096

static double absd(double value) { return value < 0.0 ? -value : value; }

static void givens(double a, double b, double *s, double *c) {
    double t;
    if (b == 0.0) { *c = 1.0; *s = 0.0; }
    else if (absd(b) > absd(a)) {
        t = -a / b;
        *s = 1.0 / sqrt(1.0 + t * t);
        *c = *s * t;
    } else {
        t = -b / a;
        *c = 1.0 / sqrt(1.0 + t * t);
        *s = *c * t;
    }
}

static void apply_givens(double *a, int n, double s, double c,
                         int i, int j, int start, int end) {
    for (int k = start; k <= end; ++k) {
        const double x = a[i * n + k], y = a[j * n + k];
        a[i * n + k] = c * x - s * y;
        a[j * n + k] = s * x + c * y;
    }
    for (int k = start; k <= end; ++k) {
        const double x = a[k * n + i], y = a[k * n + j];
        a[k * n + i] = c * x - s * y;
        a[k * n + j] = s * x + c * y;
    }
}

/* McCat's band-to-tridiagonal reduction, retaining its index/order schedule. */
static void reduce_band(double *a, int n, int bandwidth) {
    for (int i = bandwidth; i >= 2; --i) {
        for (int j = 0; j < n - i; ++j) {
            double s, c;
            givens(a[j * n + j + i - 1], a[j * n + j + i], &s, &c);
            int end = j + 2 * i < n ? j + 2 * i : n - 1;
            apply_givens(a, n, s, c, j + i - 1, j + i, j, end);
            int m = j + i;
            while (m < n - i) {
                givens(a[(m - 1) * n + m + i - 1], a[(m - 1) * n + m + i], &s, &c);
                end = m + 2 * i < n ? m + 2 * i : n - 1;
                apply_givens(a, n, s, c, m + i - 1, m + i, m - 1, end);
                m += i;
            }
        }
    }
}

static int sign_source(double value) { return value < 0.0 ? -1 : 1; }

/* Shifted symmetric QR with the source's Wilkinson shift and Givens chase. */
static int qr_iterate(double *a, int n) {
    int steps = 0;
    for (;;) {
        for (int i = 0; i < n - 1; ++i) {
            if (absd(a[(i + 1) * n + i]) <
                (absd(a[i * n + i]) + absd(a[(i + 1) * n + i + 1])) * QR_EPSILON) {
                a[(i + 1) * n + i] = 0.0;
                a[i * n + i + 1] = 0.0;
            }
        }
        int q = n - 1;
        while (q > 0 && a[(q - 1) * n + q] == 0.0) --q;
        if (q == 0) return 1;
        if (++steps > MAX_QR_STEPS) return 0;
        int p = q;
        while (p > 0 && a[(p - 1) * n + p] != 0.0) --p;
        const double d = (a[(q - 1) * n + q - 1] - a[q * n + q]) / 2.0;
        const double t = a[q * n + q - 1] * a[q * n + q - 1];
        const double mu = a[q * n + q] - t / (d + sign_source(d) * sqrt(d * d + t));
        double x = a[p * n + p] - mu;
        double z = a[(p + 1) * n + p];
        for (int i = p; i < q; ++i) {
            double s, c;
            givens(x, z, &s, &c);
            const int l = i - 1 > p ? i - 1 : p;
            const int m = q < i + 2 ? q : i + 2;
            for (int k = l; k <= m; ++k) {
                const double u = a[i * n + k], v = a[(i + 1) * n + k];
                a[i * n + k] = c * u - s * v;
                a[(i + 1) * n + k] = s * u + c * v;
            }
            for (int k = l; k <= m; ++k) {
                const double u = a[k * n + i], v = a[k * n + i + 1];
                a[k * n + i] = c * u - s * v;
                a[k * n + i + 1] = s * u + c * v;
            }
            if (i < q - 1) {
                x = a[(i + 1) * n + i];
                z = a[(i + 2) * n + i];
            }
        }
    }
}

static int32_t project(double value) {
    const double scaled = value * OUTPUT_SCALE;
    return (int32_t)(scaled >= 0.0 ? floor(scaled + 0.5) : ceil(scaled - 0.5));
}

static int before(double left, double right) {
    const double al = absd(left), ar = absd(right);
    return al > ar || (al == ar && left < right);
}

static void store_i32_le(int32_t value, uint8_t *out) {
    const uint32_t bits = (uint32_t)value;
    out[0] = (uint8_t)bits;
    out[1] = (uint8_t)(bits >> 8);
    out[2] = (uint8_t)(bits >> 16);
    out[3] = (uint8_t)(bits >> 24);
}

int64_t mccat_05_eks(const int64_t *input, size_t length,
                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], bw64 = input[1];
    if (n64 < MIN_N || n64 > MAX_N || bw64 < 2 || bw64 > 5 || bw64 >= n64) return -1;
    const int n = (int)n64, bandwidth = (int)bw64;
    if (length != (size_t)(2 + n * n)) return -1;
    double a[MAX_N * MAX_N] = {0.0};
    for (int row = 0; row < n; ++row) {
        for (int col = 0; col < n; ++col) {
            const int64_t value = input[2 + row * n + col];
            if (value < -1000000 || value > 1000000) return -1;
            if (row > col && value != input[2 + col * n + row]) return -1;
            if ((row > col ? row - col : col - row) > bandwidth && value != 0) return -1;
            a[row * n + col] = (double)value / INPUT_SCALE;
        }
    }
    const size_t required = (size_t)n * 4u;
    if (output == NULL || capacity < required) return -2;
    reduce_band(a, n, bandwidth);
    if (!qr_iterate(a, n)) return -1;
    double eigenvalues[MAX_N];
    for (int i = 0; i < n; ++i) eigenvalues[i] = a[i * n + i];
    for (int i = 1; i < n; ++i) {
        const double value = eigenvalues[i];
        int j = i;
        while (j > 0 && before(value, eigenvalues[j - 1])) {
            eigenvalues[j] = eigenvalues[j - 1];
            --j;
        }
        eigenvalues[j] = value;
    }
    uint8_t staged[MAX_OUTPUT];
    for (int i = 0; i < n; ++i) store_i32_le(project(eigenvalues[i]), staged + 4 * i);
    for (size_t i = 0; i < required; ++i) output[i] = staged[i];
    return (int64_t)required;
}
