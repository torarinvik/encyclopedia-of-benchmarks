#include <stddef.h>
#include <stdint.h>

#define TB_MAX_CAPACITY 64
#define TB_MAX_RATE 32
#define TB_MAX_REQUESTS 63
#define TB_MAX_TICKS 256
#define TB_MAX_INPUT (3 + TB_MAX_REQUESTS)

int64_t token_bucket_rate_limiter_virtual_time(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > TB_MAX_INPUT) return -1;
    const int64_t capacity = input[0], rate = input[1], request_count = input[2];
    if (capacity < 0 || capacity > TB_MAX_CAPACITY || rate < 0 || rate > TB_MAX_RATE ||
        request_count < 0 || request_count > TB_MAX_REQUESTS || length != 3 + (size_t)request_count) return -1;
    for (size_t i = 0; i < (size_t)request_count; ++i)
        if (input[3 + i] < 0 || input[3 + i] > TB_MAX_TICKS) return -1;

    int64_t tokens = capacity;
    uint64_t allowed = 0;
    for (size_t i = 0; i < (size_t)request_count; ++i) {
        tokens += input[3 + i] * rate;
        if (tokens > capacity) tokens = capacity;
        if (tokens > 0) {
            allowed |= UINT64_C(1) << i;
            --tokens;
        }
    }
    return (int64_t)allowed;
}
