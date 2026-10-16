// Keep each value that is not smaller than the last retained value.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t stalin_sort(const std::int64_t *values,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > 128 || (length != 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -1;

    std::size_t kept = 0;
    std::int64_t last = 0;
    for (std::size_t i = 0; i < length; ++i) {
        if (kept == 0 || values[i] >= last) {
            ++kept;
            last = values[i];
        }
    }
    const auto output_bytes = kept * 4;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    std::size_t output_index = 0;
    last = 0;
    for (std::size_t i = 0; i < length; ++i) {
        if (output_index == 0 || values[i] >= last) {
            const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(values[i]));
            for (std::size_t byte = 0; byte < 4; ++byte)
                output[output_index * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
            ++output_index;
            last = values[i];
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
