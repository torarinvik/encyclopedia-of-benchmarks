#include <cstdint>

extern "C" std::int64_t kolakoski_sequence(std::int64_t index) noexcept
{
    if (index < 0 || index > 63) return -1;
    if (index == 0) return 1;
    if (index <= 2) return 2;

    std::uint64_t encoded = 6; // Terms 1 and 2 are both 2.
    std::uint64_t read_bit = 4;
    std::uint64_t write_bit = 8;
    const auto target = static_cast<std::uint64_t>(index);
    std::uint64_t current_index = 3;
    std::int64_t next_element = 1;

    while (current_index <= target) {
        const std::uint64_t run_length = 1 + (encoded / read_bit) % 2;
        for (std::uint64_t emitted = 0; emitted < run_length; ++emitted) {
            if (next_element == 2) encoded += write_bit;
            if (current_index == target) return next_element;
            ++current_index;
            write_bit *= 2;
        }
        read_bit *= 2;
        next_element = 3 - next_element;
    }
    return -1;
}
