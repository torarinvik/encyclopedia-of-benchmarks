#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

int64_t hyperloglog_corrected_estimate(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 130) return -1;
    int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > 128 || length != (size_t)raw_count + 1) return -1;
    unsigned registers[16] = {0};
    for (size_t i = 0; i < (size_t)raw_count; ++i) {
        int64_t value = input[i+1];
        if (value < 0 || (uint64_t)value > UINT32_MAX) return -1;
        uint32_t hash = (uint32_t)value;
        unsigned bucket = hash >> 28;
        uint32_t suffix = hash & UINT32_C(0x0fffffff);
        unsigned rank = 1;
        for (uint32_t mask = UINT32_C(1)<<27; mask && !(suffix & mask); mask >>= 1) ++rank;
        if (rank > registers[bucket]) registers[bucket] = rank;
    }
    uint64_t sum = 0;
    unsigned zeros = 0;
    for (size_t i = 0; i < 16; ++i) {
        sum += UINT64_C(1) << (29-registers[i]);
        if (registers[i] == 0) ++zeros;
    }
    double estimate = (673.0*256.0*(double)(UINT64_C(1)<<29))/(1000.0*(double)sum);
    const double universe = 4294967296.0;
    if (estimate <= 40.0 && zeros != 0) estimate = 16.0*log(16.0/(double)zeros);
    else if (estimate > universe/30.0) {
        if (estimate >= universe) return -3;
        estimate = -universe*log1p(-estimate/universe);
    }
    if (output == NULL || capacity < 8) return -2;
    uint64_t bits;
    memcpy(&bits, &estimate, sizeof bits);
    uint8_t staged[8];
    for (size_t i = 0; i < 8; ++i) staged[i] = (uint8_t)(bits >> (8*i));
    for (size_t i = 0; i < 8; ++i) output[i] = staged[i];
    return 8;
}
