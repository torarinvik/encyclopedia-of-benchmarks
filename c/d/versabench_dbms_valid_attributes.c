#include <stddef.h>
#include <stdint.h>

#define MAX_ATTRIBUTES 51
#define MAX_INPUT_LENGTH (1 + 2 * MAX_ATTRIBUTES)

static int key_float_bits_valid(int64_t payload) {
    if (payload < 0 || (uint64_t)payload > UINT32_MAX) return -1;
    const uint32_t bits = (uint32_t)payload;
    const uint32_t exponent = (bits >> 23) & 0xffu;
    const uint32_t fraction = bits & 0x7fffffu;
    /* Source comparisons reject infinities; NaN compares neither below nor above FLT_MAX. */
    if (exponent == 0xffu && fraction == 0) return 0;
    return 1;
}

int64_t versabench_dbms_valid_attributes(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH + 1) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 0 || raw_count > MAX_ATTRIBUTES || length != 1 + 2 * (size_t)raw_count) return -1;
    for (size_t i = 0; i < (size_t)raw_count; ++i) {
        const int64_t code = values[1 + 2*i];
        const int64_t payload = values[2 + 2*i];
        if (code < 0 || code > 50) return 0;
        if (code < 8) {
            const int valid = key_float_bits_valid(payload);
            if (valid < 0) return -1;
            if (!valid) return 0;
        } else {
            if (payload != 0 && payload != 1) return -1;
            if (payload == 0) return 0;
        }
    }
    return 1;
}
