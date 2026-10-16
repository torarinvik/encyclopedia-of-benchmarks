/* Return a zero-based station index that completes the circuit, or -1. */
#include <stddef.h>
#include <stdint.h>
#define MAX_N 128
#define MAX_AMOUNT 1000000
int64_t gas_station(const int64_t *input, size_t length) {
    if (!input || length < 1 || input[0] < 0 || input[0] > MAX_N) return -2;
    size_t n=(size_t)input[0];
    if (length != 2*n+1) return -2;
    for (size_t i=0;i<2*n;i++) if (input[i+1] < 0 || input[i+1] > MAX_AMOUNT) return -2;
    int64_t total=0, current=0;
    size_t start=0;
    for (size_t i=0;i<n;i++) {
        int64_t net=input[1+i]-input[1+n+i];
        total+=net;
        current+=net;
        if (current<0) { start=i+1; current=0; }
    }
    if (total<0) return -1;
    return (int64_t)start;
}
