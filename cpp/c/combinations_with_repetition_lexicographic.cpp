#include <array>
#include <cstddef>
#include <cstdint>

namespace {
std::size_t multiset_count(std::size_t n, std::size_t r) noexcept {
    if (r == 0) return 1;
    if (n == 0) return 0;
    const auto top = n + r - 1;
    std::size_t result = 1;
    for (std::size_t index = 1; index <= r; ++index) {
        result = result * (top - r + index) / index;
    }
    return result;
}
}  // namespace

extern "C" std::int64_t combinations_with_repetition_lexicographic(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length != 2) return -1;
    if (input[0] < 0 || input[0] > 4 || input[1] < 0 || input[1] > 4) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto r = static_cast<std::size_t>(input[1]);
    const auto count = multiset_count(n, r);
    const auto byte_count = 2 + count * r;
    if (output == nullptr || capacity < byte_count) return -2;

    output[0] = static_cast<std::uint8_t>(count & 255U);
    output[1] = static_cast<std::uint8_t>((count >> 8U) & 255U);
    std::array<std::uint8_t, 4> current{};
    for (std::size_t ordinal = 0; ordinal < count; ++ordinal) {
        for (std::size_t position = 0; position < r; ++position) {
            output[2 + ordinal * r + position] = current[position];
        }
        if (ordinal + 1 == count || r == 0) continue;
        auto position = r;
        while (current[position - 1] == n - 1) --position;
        --position;
        ++current[position];
        for (auto suffix = position + 1; suffix < r; ++suffix) current[suffix] = current[position];
    }
    return static_cast<std::int64_t>(byte_count);
}
