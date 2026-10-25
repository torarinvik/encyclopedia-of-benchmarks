#include <algorithm>
#include <cstddef>
#include <cstdint>

static void write_i64_le(uint8_t *output, size_t index, int64_t value) {
    uint64_t bits = static_cast<uint64_t>(value);
    for (size_t b = 0; b < 8; ++b) output[index * 8 + b] = static_cast<uint8_t>(bits >> (8 * b));
}

extern "C" int64_t versabench_dbms_keys_union(const int64_t *values, size_t length,
    uint8_t *output, size_t output_capacity) {
    if (values == nullptr || length < 1 || length > 130) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 1 || raw_count > 16 || length != 1 + 8 * static_cast<size_t>(raw_count)) return -1;
    int64_t bounds[8];
    for (size_t d = 0; d < 4; ++d) { bounds[d] = values[1+d]; bounds[4+d] = values[5+d]; }
    for (size_t i = 0; i < static_cast<size_t>(raw_count); ++i) {
        const size_t at = 1 + 8 * i;
        for (size_t d = 0; d < 4; ++d) {
            const int64_t lo = values[at+d], hi = values[at+4+d];
            if (lo < -8 || lo > 8 || hi < -8 || hi > 8 || lo > hi) return -1;
            bounds[d] = std::min(bounds[d], lo); bounds[4+d] = std::max(bounds[4+d], hi);
        }
    }
    if (output == nullptr || output_capacity < 64) return -2;
    for (size_t i = 0; i < 8; ++i) write_i64_le(output, i, bounds[i]);
    return 64;
}
