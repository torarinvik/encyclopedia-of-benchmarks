#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 256;
constexpr std::uint64_t polynomial = UINT64_C(0x04c11db7);
}

extern "C" std::int64_t netbench_crc(const std::int64_t *values, std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 255) return -1;

    std::uint64_t table[256]{};
    for (std::uint64_t byte = 0; byte < 256; ++byte) {
        std::uint64_t remainder = byte << 24;
        for (unsigned bit = 0; bit < 8; ++bit) {
            if ((remainder & UINT64_C(0x80000000)) != 0)
                remainder = (remainder << 1) ^ polynomial;
            else
                remainder <<= 1;
        }
        table[byte] = remainder;
    }

    std::uint64_t crc = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto byte = static_cast<std::uint64_t>(values[index]);
        const auto table_index = static_cast<std::size_t>(((crc >> 24) ^ byte) & UINT64_C(0xff));
        crc = (crc << 8) ^ table[table_index];
    }
    return static_cast<std::int64_t>(crc & UINT64_C(0xffffffff));
}
