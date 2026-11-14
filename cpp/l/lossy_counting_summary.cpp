#include <array>
#include <cstddef>
#include <cstdint>

namespace {
void put_word(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t j = 0; j < 8; ++j) { output[offset+j] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t lossy_counting_summary(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 66 || input[0] < 2 || input[0] > 16 || input[1] < 0 || input[1] > 64) return -1;
    const auto width = static_cast<std::size_t>(input[0]), n = static_cast<std::size_t>(input[1]);
    if (length != 2+n) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[2+i] < 0 || input[2+i] > 15) return -1;
    std::array<std::int64_t, 16> count{}, error{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto item = static_cast<std::size_t>(input[2+i]);
        const auto bucket = static_cast<std::int64_t>(i/width+1);
        if (count[item] == 0) error[item] = bucket-1;
        ++count[item];
        if ((i+1)%width == 0) for (std::size_t j = 0; j < 16; ++j) {
            if (count[j] && count[j]+error[j] <= bucket) { count[j] = 0; error[j] = 0; }
        }
    }
    std::size_t active = 0;
    for (auto value : count) if (value) ++active;
    const auto bytes = 8+24*active;
    if (output == nullptr || capacity < bytes) return -2;
    put_word(output, 0, static_cast<std::int64_t>(active));
    std::size_t offset = 8;
    for (std::size_t i = 0; i < 16; ++i) if (count[i]) {
        put_word(output, offset, static_cast<std::int64_t>(i));
        put_word(output, offset+8, count[i]);
        put_word(output, offset+16, error[i]);
        offset += 24;
    }
    return static_cast<std::int64_t>(bytes);
}
