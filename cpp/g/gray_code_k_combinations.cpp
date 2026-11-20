#include <cstddef>
#include <cstdint>

namespace {
std::size_t combination_count(unsigned n, unsigned k) noexcept {
    const unsigned choose = k < n - k ? k : n - k;
    std::size_t count = 1;
    for (unsigned i = 1; i <= choose; ++i) count = count * (n - choose + i) / i;
    return count;
}

void write_u16(std::uint8_t *output, std::size_t offset, std::uint16_t value) noexcept {
    output[offset] = static_cast<std::uint8_t>(value & 255u);
    output[offset + 1] = static_cast<std::uint8_t>(value >> 8);
}
}

extern "C" std::int64_t gray_code_k_combinations(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 2 || input[0] < 0 || input[0] > 12 ||
        input[1] < 0 || input[1] > input[0]) return -1;
    const auto n = static_cast<unsigned>(input[0]);
    const auto k = static_cast<unsigned>(input[1]);
    const auto count = combination_count(n, k);
    const auto required = std::size_t{2} + 2 * count;
    if (output == nullptr || capacity < required) return -2;
    write_u16(output, 0, static_cast<std::uint16_t>(count));

    std::size_t emitted = 0;
    const auto limit = std::uint32_t{1} << n;
    for (std::uint32_t index = 0; index < limit; ++index) {
        const auto mask = index ^ (index >> 1);
        auto bits = mask;
        unsigned population = 0;
        while (bits != 0) { bits &= bits - 1; ++population; }
        if (population == k) write_u16(output, 2 + 2 * emitted++, static_cast<std::uint16_t>(mask));
    }
    return static_cast<std::int64_t>(count);
}
