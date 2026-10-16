/* Bottom-up merge passes over two bounded buffers, modeling sequential stores. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 4096;

void merge_pass(const std::int64_t *source, std::int64_t *destination,
                std::size_t length, std::size_t width) noexcept
{
    for (std::size_t start = 0; start < length; start += width * 2) {
        std::size_t middle = start + width;
        if (middle > length) middle = length;
        std::size_t end = middle + width;
        if (end > length) end = length;
        std::size_t left = start, right = middle, out = start;
        while (left < middle && right < end)
            destination[out++] = source[left] < source[right] ? source[left++] : source[right++];
        while (left < middle) destination[out++] = source[left++];
        while (right < end) destination[out++] = source[right++];
    }
}
}

extern "C" std::int64_t external_merge_sorter(const std::int64_t *values,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length > max_values || (length != 0 && values == nullptr)) return -1;
    const std::size_t output_bytes = length * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    std::int64_t primary[max_values], temporary[max_values];
    for (std::size_t index = 0; index < length; ++index) primary[index] = values[index];
    std::int64_t *source = primary, *destination = temporary;
    for (std::size_t width = 1; width < length;) {
        merge_pass(source, destination, length, width);
        auto *swap = source;
        source = destination;
        destination = swap;
        if (width > length / 2) break;
        width *= 2;
    }
    for (std::size_t index = 0; index < length; ++index) {
        const auto bits = static_cast<std::uint64_t>(source[index]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(output_bytes);
}
