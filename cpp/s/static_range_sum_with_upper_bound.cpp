#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

extern "C" int64_t static_range_sum_with_upper_bound(const int64_t *input, size_t length,
                                                     uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 258 || input[0] < 1 || input[0] > 64 ||
        input[1] < 1 || input[1] > 64) return -1;
    const auto n = static_cast<size_t>(input[0]);
    const auto q = static_cast<size_t>(input[1]);
    if (length != 2+n+3*q) return -1;
    std::vector<uint32_t> values;
    values.reserve(n);
    for (size_t i = 0; i < n; ++i) {
        if (input[2+i] < 0 || input[2+i] > 1000000000) return -1;
        values.push_back(static_cast<uint32_t>(input[2+i]));
    }
    for (size_t i = 0; i < q; ++i) {
        const auto l = input[2+n+3*i], r = input[3+n+3*i], x = input[4+n+3*i];
        if (l < 0 || l > r || r > static_cast<int64_t>(n) || x < 0 || x > 1000000000) return -1;
    }
    if (!output || capacity < 16*q) return -2;
    std::array<std::array<size_t, 65>, 30> counts{};
    std::array<std::array<uint64_t, 65>, 30> sums{};
    std::array<size_t, 30> offsets{};
    for (size_t level = 0; level < 30; ++level) {
        const uint32_t mask = uint32_t{1} << (29-level);
        for (size_t i = 0; i < n; ++i) {
            const bool zero = (values[i] & mask) == 0;
            counts[level][i+1] = counts[level][i] + zero;
            sums[level][i+1] = sums[level][i] + (zero ? values[i] : 0);
        }
        offsets[level] = counts[level][n];
        std::vector<uint32_t> next;
        next.reserve(n);
        for (auto value : values) if ((value & mask) == 0) next.push_back(value);
        for (auto value : values) if ((value & mask) != 0) next.push_back(value);
        values.swap(next);
    }
    for (size_t i = 0; i < q; ++i) {
        size_t l = static_cast<size_t>(input[2+n+3*i]), r = static_cast<size_t>(input[3+n+3*i]);
        const auto key = static_cast<uint32_t>(input[4+n+3*i]) + 1;
        uint64_t count = 0, sum = 0;
        for (size_t level = 0; level < 30; ++level) {
            const auto zl = counts[level][l], zr = counts[level][r];
            if (key & (uint32_t{1} << (29-level))) {
                count += zr-zl; sum += sums[level][r]-sums[level][l];
                l += offsets[level]-zl; r += offsets[level]-zr;
            } else { l = zl; r = zr; }
        }
        for (size_t byte = 0; byte < 8; ++byte) {
            output[16*i+byte] = static_cast<uint8_t>(count >> (8*byte));
            output[16*i+8+byte] = static_cast<uint8_t>(sum >> (8*byte));
        }
    }
    return static_cast<int64_t>(16*q);
}
