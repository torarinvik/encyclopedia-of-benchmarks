#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define MAX_N 8
#define MAX_ENTRY 1000000000LL
#define TOL 1.0e-10

static void put_f64(uint8_t *out, size_t offset, double x) {
    uint64_t bits;
    memcpy(&bits, &x, sizeof(bits));
    for (size_t i = 0; i < 8; ++i) out[offset+i] = (uint8_t)(bits >> (8*i));
}

int64_t gauss_seidel_method(const int64_t *v, size_t len, uint8_t *out, size_t cap) {
    if (!v || len < 1 || v[0] < 1 || v[0] > MAX_N) return -1;
    const size_t n = (size_t)v[0];
    if (len != 1+n*n+n) return -1;
    const size_t rhs = 1+n*n;
    for (size_t k = 1; k < len; ++k) if (v[k] < -MAX_ENTRY || v[k] > MAX_ENTRY) return -1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t d = v[1+i*n+i];
        int64_t sum = 0;
        if (d <= 0) return -1;
        for (size_t j = 0; j < n; ++j) {
            if (v[1+i*n+j] != v[1+j*n+i]) return -1;
            if (i != j) sum += llabs(v[1+i*n+j]);
        }
        if (d <= sum) return -1;
    }
    if (!out || cap < n*8) return -2;
    double a[MAX_N*MAX_N], b[MAX_N], x[MAX_N] = {0};
    for (size_t i = 0; i < n*n; ++i) a[i] = (double)v[i+1] / 1000000.0;
    for (size_t i = 0; i < n; ++i) b[i] = (double)v[rhs+i] / 1000000.0;
    for (int iteration = 0; iteration < 1000; ++iteration) {
        double old[MAX_N];
        memcpy(old, x, n*sizeof(double));
        for (size_t i = 0; i < n; ++i) {
            double before = 0.0, after = 0.0;
            for (size_t j = 0; j < i; ++j) before += a[i*n+j]*x[j];
            for (size_t j = i+1; j < n; ++j) after += a[i*n+j]*old[j];
            x[i] = (b[i]-before-after)/a[i*n+i];
        }
        int done = 1;
        for (size_t i = 0; i < n; ++i) if (fabs(x[i]-old[i]) >= TOL) done = 0;
        if (done) break;
    }
    for (size_t i = 0; i < n; ++i) put_f64(out, i*8, round(x[i]*1.0e10)/1.0e10);
    return (int64_t)(n*8);
}
