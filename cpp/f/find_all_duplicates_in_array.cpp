// Sort a copy, then emit each value that appears twice.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace { constexpr std::size_t max_length = 100000; }

extern "C" std::int64_t find_all_duplicates_in_array(
        const std::int64_t *values, std::size_t length,
        std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -1;
    if (length == 0) return 0;

    std::vector<std::int32_t> sorted;
    sorted.reserve(length);
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 1 || values[index] > static_cast<std::int64_t>(length)) return -1;
        sorted.push_back(static_cast<std::int32_t>(values[index]));
    }
    std::sort(sorted.begin(), sorted.end());

    std::size_t duplicate_count = 0;
    for (std::size_t index = 0; index < length;) {
        std::size_t end = index + 1;
        while (end < length && sorted[end] == sorted[index]) ++end;
        const std::size_t frequency = end - index;
        if (frequency > 2) return -1;
        if (frequency == 2) ++duplicate_count;
        index = end;
    }
    const std::size_t output_bytes = duplicate_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    std::size_t destination = 0;
    for (std::size_t index = 0; index < length;) {
        std::size_t end = index + 1;
        while (end < length && sorted[end] == sorted[index]) ++end;
        if (end - index == 2) {
            const auto value = static_cast<std::uint32_t>(sorted[index]);
            for (std::size_t byte = 0; byte < 4; ++byte)
                output[destination * 4 + byte] = static_cast<std::uint8_t>(value >> (byte * 8));
            ++destination;
        }
        index = end;
    }
    return static_cast<std::int64_t>(duplicate_count);
}
