#include <stddef.h>
#include <stdint.h>

int64_t reservoir_sampling_algorithm_r(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 130 || input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > input[0]) return -1;
    size_t n = (size_t)input[0], k = (size_t)input[1];
    if (length != 2+2*n-k) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2+i] < -1000000 || input[2+i] > 1000000) return -1;
    for (size_t i = k; i < n; ++i) if (input[2+n+i-k] < 0 || input[2+n+i-k] > (int64_t)i) return -1;
    if (output == NULL || capacity < 8*k) return -2;
    int64_t reservoir[64];
    for (size_t i = 0; i < k; ++i) reservoir[i] = input[2+i];
    for (size_t i = k; i < n; ++i) {
        size_t draw = (size_t)input[2+n+i-k];
        if (draw < k) reservoir[draw] = input[2+i];
    }
    for (size_t i = 0; i < k; ++i) {
        uint64_t encoded = (uint64_t)reservoir[i];
        for (size_t j = 0; j < 8; ++j) { output[8*i+j] = (uint8_t)(encoded & 255u); encoded >>= 8; }
    }
    return (int64_t)(8*k);
}
