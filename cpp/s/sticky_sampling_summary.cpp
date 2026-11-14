#include <array>
#include <cstddef>
#include <cstdint>

namespace {
void put_word(std::uint8_t* out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { out[offset+i] = static_cast<std::uint8_t>(bits); bits >>= 8; }
}
}

extern "C" std::int64_t sticky_sampling_summary(const std::int64_t* input, std::size_t length,
                                                  std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 3 || length > 323 || input[0] < 1 || input[0] > 8 ||
        input[1] < 0 || input[1] > 64 || input[2] < 0 || input[2] > 256) return -1;
    const auto t = static_cast<std::size_t>(input[0]), n = static_cast<std::size_t>(input[1]);
    const auto k = static_cast<std::size_t>(input[2]);
    if (length != 3+n+k) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[3+i] < 0 || input[3+i] > 15) return -1;
    for (std::size_t i = 0; i < k; ++i) if (input[3+n+i] < 0 || input[3+n+i] > 255) return -1;
    std::array<std::int64_t, 16> counts{};
    std::size_t cursor = 0, rate = 1, end = 2*t;
    for (std::size_t i = 0; i < n; ++i) {
        if (i == end) {
            rate *= 2; end += rate*t;
            for (auto& count : counts) while (count) {
                if (cursor == k) return -1;
                if (input[3+n+cursor++] & 1) break;
                --count;
            }
        }
        auto item = static_cast<std::size_t>(input[3+i]);
        if (counts[item]) ++counts[item];
        else {
            if (cursor == k) return -1;
            auto draw = static_cast<std::size_t>(input[3+n+cursor++]);
            if (draw % rate == 0) counts[item] = 1;
        }
    }
    if (cursor != k) return -1;
    std::size_t active = 0;
    for (auto count : counts) active += count != 0;
    const auto bytes = 8+16*active;
    if (!output || capacity < bytes) return -2;
    put_word(output, 0, static_cast<std::int64_t>(active));
    std::size_t offset = 8;
    for (std::size_t i = 0; i < counts.size(); ++i) if (counts[i]) {
        put_word(output, offset, static_cast<std::int64_t>(i));
        put_word(output, offset+8, counts[i]);
        offset += 16;
    }
    return static_cast<std::int64_t>(bytes);
}
