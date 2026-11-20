#include <cstddef>
#include <cstdint>

extern "C" std::int64_t nmea_xor_checksum(const std::int64_t *values,
                                            std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > 78) return -1;
    const std::int64_t payload_length = values[0];
    if (payload_length < 0 || payload_length > 76 ||
        static_cast<std::size_t>(payload_length) + 1 != length) return -1;

    std::uint8_t checksum = 0;
    for (std::size_t i = 1; i < length; ++i) {
        if (values[i] < 0 || values[i] > 127) return -1;
        checksum ^= static_cast<std::uint8_t>(values[i]);
    }
    return checksum;
}
