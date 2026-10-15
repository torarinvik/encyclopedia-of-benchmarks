/* Evaluate net present value for each supplied discount rate. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

static void put_f64_le(uint8_t *out, size_t offset, double value) {
    uint64_t bits; memcpy(&bits, &value, 8);
    for (size_t b=0;b<8;++b) out[offset+b]=(uint8_t)(bits>>(8*b));
}
int64_t npv_sensitivity(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 2 || input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 32) return -1;
    size_t n=(size_t)input[0], rates=(size_t)input[1];
    if (length != 2+n+rates) return -1;
    for (size_t t=0;t<n;++t) if (input[2+t] < -1000000 || input[2+t] > 1000000) return -1;
    for (size_t r=0;r<rates;++r) if (input[2+n+r] < 0 || input[2+n+r] > 1000) return -1;
    if (capacity < rates*8 || (rates > 0 && !output)) return -2;
    for (size_t r=0;r<rates;++r) {
        double rate=(double)input[2+n+r]/10000.0, total=0.0;
        for (size_t t=0;t<n;++t) {
            double term=(double)input[2+t]/pow(1.0+rate,(double)t);
            total+=term;
        }
        put_f64_le(output,r*8,total);
    }
    return (int64_t)(rates*8);
}
