#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_words = 160;
constexpr std::size_t max_output_bytes = 18;
constexpr std::array<std::uint16_t, 32> raw5 = {
    0x0d80, 0x05a2, 0x0c60, 0x0cc0, 0x0ca0, 0x10a2, 0x10c2, 0x10e0,
    0x0d20, 0x1122, 0x1142, 0x1160, 0x1182, 0x11a0, 0x11c0, 0x05e0,
    0x0e20, 0x1222, 0x1242, 0x1260, 0x1282, 0x12a0, 0x12c0, 0x06e0,
    0x1302, 0x1320, 0x1340, 0x0760, 0x0380, 0x07a0, 0x0e80, 0x06a2
};
constexpr std::array<std::uint16_t, 8> raw3 = {
    0x0c08, 0x0c04, 0x1009, 0x100c, 0x1011, 0x1014, 0x0018, 0x041c
};

std::uint32_t encode_one(std::uint32_t packed_word, std::uint32_t &disparity) noexcept {
    const auto data = packed_word & 0xffU;
    const auto k = packed_word >> 8;
    const auto index5 = data >> 3;
    const auto index3 = data & 7U;
    std::uint32_t lookup5 = raw5[index5];
    std::uint32_t lookup3 = raw3[index3];
    if (k == 1U && index5 == 7U) lookup5 = 0x04e2U;
    if (k == 1U) {
        if (index3 >= 2U && index3 <= 5U)
            lookup3 = (lookup3 & ~0x1000U) | 0x0800U;
        else if (index3 == 7U)
            lookup3 = 0x040dU;
    }

    std::uint32_t result;
    std::uint32_t disparity1;
    if ((lookup5 & 0x1000U) != 0U) {
        result = lookup5 & 0x03e2U;
        disparity1 = disparity;
    } else {
        const std::uint32_t code5 = lookup5 & 0x03e2U;
        const bool plus5 = (lookup5 & 0x0800U) != 0U;
        result = (disparity == static_cast<std::uint32_t>(plus5)) ? code5 : code5 ^ 0x03e2U;
        disparity1 = disparity ^ static_cast<std::uint32_t>((lookup5 & 0x0400U) != 0U);
    }

    if ((lookup3 & 0x1000U) != 0U) {
        result |= lookup3 & 0x001dU;
        disparity = disparity1;
    } else {
        const std::uint32_t code3 = lookup3 & 0x001dU;
        const bool plus3 = (lookup3 & 0x0800U) != 0U;
        result |= (disparity1 == static_cast<std::uint32_t>(plus3)) ? code3 : code3 ^ 0x001dU;
        disparity = disparity1 ^ static_cast<std::uint32_t>((lookup3 & 0x0400U) != 0U);
    }
    return result;
}

std::size_t append_line(std::uint32_t value, std::array<std::uint8_t, max_output_bytes> &staged,
                        std::size_t used) noexcept {
    constexpr char hex[] = "0123456789ABCDEF";
    for (std::size_t digit = 0; digit < 8; ++digit) {
        const auto shift = static_cast<unsigned>((7U - digit) * 4U);
        staged[used++] = static_cast<std::uint8_t>(hex[(value >> shift) & 15U]);
    }
    staged[used++] = static_cast<std::uint8_t>('\n');
    return used;
}
}

extern "C" std::int64_t versabench_8b10b(const std::int64_t *values, std::size_t length,
                                         std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_words || (length != 0 && values == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 511) return -1;

    const std::size_t sample_count = length == 0 ? 0 : 1 + (length - 1) / 128;
    const std::size_t required = sample_count * 9;
    if (required != 0 && (output == nullptr || output_capacity < required)) return -2;

    std::array<std::uint8_t, max_output_bytes> staged{};
    std::size_t used = 0;
    std::uint32_t disparity = 0;
    for (std::size_t pass = 0; pass < length; ++pass) {
        for (std::size_t index = 0; index < length; ++index) {
            const auto encoded = encode_one(static_cast<std::uint32_t>(values[index]), disparity);
            if (pass + 1 == length && index % 128 == 0)
                used = append_line(encoded, staged, used);
        }
    }
    for (std::size_t index = 0; index < required; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(used);
}
