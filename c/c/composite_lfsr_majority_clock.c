/* One majority-clock step for the three source-configured A5 LFSRs. */
#include <stddef.h>
#include <stdint.h>

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)((bits >> (8 * byte)) & 0xffu);
}

int64_t composite_lfsr_majority_clock(const int64_t *input, size_t length,
                                      uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != 3) return -1;
    if (input[0] < 0 || input[0] > 524287 || input[1] < 0 || input[1] > 4194303
        || input[2] < 0 || input[2] > 8388607) return -1;
    if (output == NULL || output_capacity < 32) return -2;

    uint64_t s1 = (uint64_t)input[0], s2 = (uint64_t)input[1], s3 = (uint64_t)input[2];
    const uint64_t clocks[3] = {(s1 >> 8) & 1u, (s2 >> 10) & 1u, (s3 >> 10) & 1u};
    const uint64_t majority = (clocks[0] + clocks[1] + clocks[2] >= 2) ? 1u : 0u;
    const uint64_t emitted = ((s1 >> 18) ^ (s2 >> 21) ^ (s3 >> 22)) & 1u;
    if (clocks[0] == majority) s1 = ((s1 << 1) & 524287u) | (((s1 >> 13) ^ (s1 >> 16) ^ (s1 >> 17) ^ (s1 >> 18)) & 1u);
    if (clocks[1] == majority) s2 = ((s2 << 1) & 4194303u) | (((s2 >> 20) ^ (s2 >> 21)) & 1u);
    if (clocks[2] == majority) s3 = ((s3 << 1) & 8388607u) | (((s3 >> 7) ^ (s3 >> 20) ^ (s3 >> 21) ^ (s3 >> 22)) & 1u);
    write_i64_le(output, 0, (int64_t)emitted);
    write_i64_le(output, 8, (int64_t)s1);
    write_i64_le(output, 16, (int64_t)s2);
    write_i64_le(output, 24, (int64_t)s3);
    return 32;
}
