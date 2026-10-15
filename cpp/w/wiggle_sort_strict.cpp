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

extern "C" std::int64_t wiggle_sort_strict(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == nullptr)) return -1;
    std::int64_t values[MAX_ARRAY_LENGTH];

    for (std::size_t i = 0; i < length; ++i) {
        if (input[i] < INT32_MIN || input[i] > INT32_MAX) return -1;
        values[i] = input[i];
    }
    const std::size_t bytes = length * 4;
    if (output_capacity < bytes || (bytes != 0 && output == nullptr)) return -2;
    if (length == 0) return 0;

    const std::int64_t median = select_kth(values, length, length / 2);
    std::size_t median_count = 0;
    std::int64_t smallest_value = values[0];
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] == median) ++median_count;
        if (values[index] < smallest_value) smallest_value = values[index];
    }
    const std::size_t maximum_medians = (length + 1) / 2;
    if (median_count > maximum_medians
        || (length % 2 == 1 && median_count == maximum_medians && smallest_value != median)) return -1;

    std::ptrdiff_t i = 0, j = 0, k = static_cast<std::ptrdiff_t>(length) - 1;
    const std::ptrdiff_t modulus = static_cast<std::ptrdiff_t>(length) + 1
        - static_cast<std::ptrdiff_t>(length % 2);
    while (j <= k) {
        const std::ptrdiff_t mapped_j = (2 * j + 1) % modulus;
        if (values[mapped_j] > median) {
            const std::ptrdiff_t mapped_i = (2 * i + 1) % modulus;
            const auto temporary = values[mapped_j];
            values[mapped_j] = values[mapped_i];
            values[mapped_i] = temporary;
            ++i;
            ++j;
        } else if (values[mapped_j] < median) {
            const std::ptrdiff_t mapped_k = (2 * k + 1) % modulus;
            const auto temporary = values[mapped_j];
            values[mapped_j] = values[mapped_k];
            values[mapped_k] = temporary;
            --k;
        } else {
            ++j;
        }
    }
    for (std::size_t i = 0; i < length; ++i) {
        const std::uint32_t bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(values[i]));
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[i * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(length);
}
