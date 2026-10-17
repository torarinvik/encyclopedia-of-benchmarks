#include <cstddef>
#include <cstdint>

namespace {
void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

bool is_removed(std::int64_t value, const std::int64_t* input, std::size_t n, std::size_t by) {
    if (by == 0) return true;
    const std::size_t suffix_start = n - by;
    for (std::size_t key = suffix_start; key < n; ++key) {
        if (value == input[2 + key]) return true;
    }
    return false;
}
}

extern "C" std::int64_t shorten_vector(const std::int64_t* input, std::size_t length,
                                         std::uint8_t* output, std::size_t capacity) noexcept {
    constexpr std::int64_t max_length = 64;
    constexpr std::size_t max_input_length = 67;
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t raw_n = input[0], raw_by = input[1];
    if (raw_n < 0 || raw_n > max_length || raw_by < 0 || raw_by > raw_n) return -1;
    const auto n = static_cast<std::size_t>(raw_n), by = static_cast<std::size_t>(raw_by);
    if (length != 2 + n) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        if (input[2 + i] < -1'000'000 || input[2 + i] > 1'000'000) return -1;
    }

    std::size_t survivor_count = 0;
    for (std::size_t i = 0; i < n; ++i) {
        if (!is_removed(input[2 + i], input, n, by)) ++survivor_count;
    }
    const std::size_t bytes = survivor_count * 8;
    if (output == nullptr || capacity < bytes) return -2;

    std::size_t written = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[2 + i];
        if (!is_removed(value, input, n, by)) put_i64_le(output, written++ * 8, value);
    }
    return static_cast<std::int64_t>(bytes);
}
