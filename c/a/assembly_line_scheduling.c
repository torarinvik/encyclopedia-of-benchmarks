/* Minimum time to cross two assembly lines using station-by-station dynamic programming. */
#include <stddef.h>
#include <stdint.h>

int64_t assembly_line_scheduling(const int64_t *values, size_t length,
                                 uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 7) return -1;
    if (values[0] < 1 || values[0] > 64) return -1;
    const size_t n = (size_t)values[0];
    if (length != 4 * n + 3) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 1000) return -1;

    const size_t a0 = 1;
    const size_t a1 = a0 + n;
    const size_t t0 = a1 + n;
    const size_t t1 = t0 + n - 1;
    const size_t entry = t1 + n - 1;
    int64_t line0 = values[entry] + values[a0];
    int64_t line1 = values[entry + 1] + values[a1];
    for (size_t station = 1; station < n; ++station) {
        const int64_t next0 = (line0 + values[a0 + station] <
                               line1 + values[t1 + station - 1] + values[a0 + station])
                                  ? line0 + values[a0 + station]
                                  : line1 + values[t1 + station - 1] + values[a0 + station];
        const int64_t next1 = (line1 + values[a1 + station] <
                               line0 + values[t0 + station - 1] + values[a1 + station])
                                  ? line1 + values[a1 + station]
                                  : line0 + values[t0 + station - 1] + values[a1 + station];
        line0 = next0;
        line1 = next1;
    }
    const int64_t total0 = line0 + values[entry + 2];
    const int64_t total1 = line1 + values[entry + 3];
    const int64_t answer = total0 < total1 ? total0 : total1;
    if (output == NULL || output_capacity < 4) return -2;
    const uint32_t bits = (uint32_t)(int32_t)answer;
    for (size_t byte = 0; byte < 4; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
    return 4;
}
