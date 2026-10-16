#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 1024
#define REGISTER_COUNT 65536

int64_t hyper_log_log(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_COUNT + 1) return -1;
    const int64_t count64 = input[0];
    if (count64 < 1 || count64 > MAX_COUNT || length != (size_t)count64 + 1) return -1;
    const size_t count = (size_t)count64;
    for (size_t i = 0; i < count; ++i) if (input[1 + i] < 1 || input[1 + i] > REGISTER_COUNT - 1) return -1;

    uint8_t registers[REGISTER_COUNT] = {0};
    uint8_t seen[REGISTER_COUNT] = {0};
    uint16_t touched[MAX_COUNT];
    size_t touched_count = 0;
    for (size_t i = 0; i < count; ++i) {
        const uint32_t value = (uint32_t)input[1 + i];
        uint32_t bits = value;
        uint8_t rank = 0;
        while ((bits & 1u) == 0u) { ++rank; bits >>= 1; }
        if (seen[value] == 0) {
            seen[value] = 1;
            touched[touched_count++] = (uint16_t)value;
        }
        if (rank > registers[value]) registers[value] = rank;
    }

    double z = 0.0;
    for (size_t i = 0; i < touched_count; ++i) {
        z += 1.0 / (double)(1u << registers[touched[i]]);
    }
    const double k = (double)touched_count;
    return (int64_t)ceil(0.673 * k * (k / z));
}
