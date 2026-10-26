#include <math.h>
#include <stddef.h>

static int seed_ok(double x) { return x == -1.0 || x == -0.5 || x == 0.0 || x == 0.5 || x == 1.0; }

long long tsvc_s222_interleaved_square_recurrence(const double *input, size_t length,
                                                   double *output, size_t capacity) {
    if (input == NULL || length < 5 || length > 257) return -1;
    double rn = input[0];
    if (!isfinite(rn) || trunc(rn) != rn || rn < 1.0 || rn > 64.0) return -1;
    size_t n = (size_t)rn;
    if (length != 1 + 4*n) return -1;
    for (size_t i=1; i<1+3*n; ++i)
        if (!isfinite(input[i]) || trunc(input[i]) != input[i] || fabs(input[i]) > 2.0) return -1;
    for (size_t i=1+3*n; i<length; ++i)
        if (!isfinite(input[i]) || !seed_ok(input[i])) return -1;
    size_t required = 2*n;
    if (output == NULL || capacity < required) return -2;
    double a[64], e[64];
    for (size_t i=0; i<n; ++i) { a[i]=input[1+i]; e[i]=input[1+3*n+i]; }
    for (size_t i=1; i<n; ++i) {
        double product=input[1+n+i]*input[1+2*n+i];
        a[i]=a[i]+product;
        e[i]=e[i-1]*e[i-1];
        a[i]=a[i]-product;
    }
    for (size_t i=0; i<n; ++i) { output[i]=a[i]; output[n+i]=e[i]; }
    return (long long)required;
}
