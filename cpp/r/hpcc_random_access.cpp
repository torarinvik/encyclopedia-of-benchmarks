#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_table_size = 256;
constexpr std::uint64_t digest_mask = UINT64_C(0x7fffffffffffffff);
}

extern "C" std::int64_t hpcc_random_access(const std::int64_t* input,
                                            std::size_t length) noexcept {
    if (input == nullptr || length != 1) return -1;
    const std::int64_t size_value = input[0];
    if (size_value < 2 || size_value > static_cast<std::int64_t>(max_table_size)
        || (size_value & (size_value - 1)) != 0) return -1;

    const auto size = static_cast<std::size_t>(size_value);
    std::array<std::uint64_t, max_table_size> table{};
    for (std::size_t index = 0; index < size; ++index) {
        table[index] = static_cast<std::uint64_t>(index);
    }

    std::uint64_t ran = 1;
    for (std::size_t update = 0; update < 4 * size; ++update) {
        const std::uint64_t feedback = (ran >> 63) != 0 ? 7 : 0;
        ran = (ran << 1) ^ feedback;
        table[ran & static_cast<std::uint64_t>(size - 1)] ^= ran;
    }

    std::uint64_t digest = 0;
    for (std::size_t index = 0; index < size; ++index) {
        digest += static_cast<std::uint64_t>(index + 1) * table[index];
    }
    return static_cast<std::int64_t>(digest & digest_mask);
}
