#include <cmath>
#include <cstddef>

static bool seed_ok(double x) { return x == -1.0 || x == -0.5 || x == 0.0 || x == 0.5 || x == 1.0; }

extern "C" long long tsvc_s222_interleaved_square_recurrence(const double *input, std::size_t length,
                                                               double *output, std::size_t capacity) {
    if (!input || length < 5 || length > 257) return -1;
    double rn=input[0];
    if (!std::isfinite(rn) || std::trunc(rn)!=rn || rn<1.0 || rn>64.0) return -1;
    std::size_t n=static_cast<std::size_t>(rn);
    if (length != 1+4*n) return -1;
    for (std::size_t i=1; i<1+3*n; ++i)
        if (!std::isfinite(input[i]) || std::trunc(input[i])!=input[i] || std::fabs(input[i])>2.0) return -1;
    for (std::size_t i=1+3*n; i<length; ++i)
        if (!std::isfinite(input[i]) || !seed_ok(input[i])) return -1;
    const std::size_t required=2*n;
    if (!output || capacity<required) return -2;
    double a[64], e[64];
    for (std::size_t i=0;i<n;++i) { a[i]=input[1+i]; e[i]=input[1+3*n+i]; }
    for (std::size_t i=1;i<n;++i) {
        const double product=input[1+n+i]*input[1+2*n+i];
        a[i]=a[i]+product;
        e[i]=e[i-1]*e[i-1];
        a[i]=a[i]-product;
    }
    for (std::size_t i=0;i<n;++i) { output[i]=a[i]; output[n+i]=e[i]; }
    return static_cast<long long>(required);
}
