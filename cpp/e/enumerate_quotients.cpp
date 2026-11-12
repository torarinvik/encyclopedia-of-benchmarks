#include <cstddef>
#include <cstdint>

extern "C" std::int64_t enumerate_quotients(std::int64_t value, std::uint8_t* output,
                                              std::size_t output_capacity) noexcept {
    constexpr std::int64_t max_n = 100'000;
    if (value < 1 || value > max_n) return -1;
    const std::uint64_t n = static_cast<std::uint64_t>(value);
    std::size_t count = 0;
    for (std::uint64_t left = 1; left <= n;) {
        const std::uint64_t quotient = n / left;
        ++count;
        left = n / quotient + 1;
    }
    const std::size_t byte_count = (count + 1) * 8;
    if (output == nullptr || output_capacity < byte_count) return -2;
    const std::uint64_t count_word = static_cast<std::uint64_t>(count);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(count_word >> (byte * 8));
    std::size_t index = 0;
    for (std::uint64_t left = 1; left <= n;) {
        const std::uint64_t quotient = n / left;
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[(index + 1) * 8 + byte] = static_cast<std::uint8_t>(quotient >> (byte * 8));
        ++index;
        left = n / quotient + 1;
    }
    return static_cast<std::int64_t>(byte_count);
}
