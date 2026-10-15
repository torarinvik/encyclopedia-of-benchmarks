#include <cstddef>
#include <cstdint>
static constexpr std::size_t MAX_ARRAY_LENGTH = 4096;

static std::int64_t select_kth(std::int64_t *values, std::size_t count, std::size_t target) {
    std::ptrdiff_t low = 0;
    std::ptrdiff_t high = static_cast<std::ptrdiff_t>(count) - 1;
    while (low < high) {
        std::ptrdiff_t left = low;
        std::ptrdiff_t right = high;
        const std::int64_t pivot = values[static_cast<std::size_t>((left + right + 1) / 2)];
        while (left <= right) {
            while (left <= right && values[left] < pivot) ++left;
            while (left <= right && values[right] > pivot) --right;
            if (left <= right) {
                const auto temporary = values[left];
                values[left] = values[right];
                values[right] = temporary;
                ++left;
                --right;
            }
        }
        if (static_cast<std::ptrdiff_t>(target) <= right) high = right;
        else if (static_cast<std::ptrdiff_t>(target) >= left) low = left;
        else break;
    }
    return values[target];
}

extern "C" std::int64_t simplified_wiggle_sort(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == nullptr)) return -1;
    std::int64_t values[MAX_ARRAY_LENGTH];
    std::int64_t ordered[MAX_ARRAY_LENGTH];
    for (std::size_t i = 0; i < length; ++i) {
        if (input[i] < INT32_MIN || input[i] > INT32_MAX) return -1;
        values[i] = input[i];
    }
    const std::size_t bytes = length * 4;
    if (output_capacity < bytes || (bytes != 0 && output == nullptr)) return -2;
    if (length == 0) return 0;

    const std::int64_t median = select_kth(values, length, length / 2);
    std::size_t smaller = 0;
    std::ptrdiff_t greater = static_cast<std::ptrdiff_t>(length - 1 - (length % 2));
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] > median) {
            ordered[greater] = values[i];
            greater -= 2;
        } else if (smaller < length) {
            ordered[smaller] = values[i];
            smaller += 2;
        } else {
            ordered[greater] = values[i];
            greater -= 2;
        }
    }
    for (std::size_t i = 0; i < length; ++i) {
        const std::uint32_t bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(ordered[i]));
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[i * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(length);
}
