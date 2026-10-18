#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 5, max_input = 7, max_output = 601; }

extern "C" std::int64_t permutation_unique_string(const std::int64_t* input, std::size_t input_length,
                                                   std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || input_length == 0 || input_length > max_input || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_length) || input_length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto length = static_cast<std::size_t>(input[0]);
    std::array<std::uint8_t, max_length> current{};
    for (std::size_t i = 0; i < length; ++i) {
        if (input[i + 1] < 32 || input[i + 1] > 126) return -1;
        current[i] = static_cast<std::uint8_t>(input[i + 1]);
    }
    std::sort(current.begin(), current.begin() + static_cast<std::ptrdiff_t>(length));
    std::array<std::uint8_t, max_output> staged{};
    std::size_t count = 0;
    for (;;) {
        for (std::size_t i = 0; i < length; ++i) staged[1 + count * length + i] = current[i];
        ++count;
        if (length < 2) break;
        std::size_t pivot = length - 1;
        while (pivot > 0 && current[pivot - 1] >= current[pivot]) --pivot;
        if (pivot == 0) break;
        std::size_t successor = length - 1;
        while (current[successor] <= current[pivot - 1]) --successor;
        std::swap(current[pivot - 1], current[successor]);
        std::reverse(current.begin() + static_cast<std::ptrdiff_t>(pivot), current.begin() + static_cast<std::ptrdiff_t>(length));
    }
    staged[0] = static_cast<std::uint8_t>(count);
    const std::size_t output_size = 1 + count * length;
    if (output == nullptr || capacity < output_size) return -2;
    std::copy_n(staged.begin(), output_size, output);
    return static_cast<std::int64_t>(output_size);
}
