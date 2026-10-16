// Bounded Flash Sort followed by the source's insertion-sort finishing pass.
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 64;
bool valid_length(std::size_t length) { return length <= 1 || (length >= 3 && length <= MAX_LENGTH); }
std::size_t class_of(std::int64_t value, std::int64_t minimum, std::int64_t range, std::size_t classes) {
    return static_cast<std::size_t>(static_cast<std::int64_t>(classes - 1) * (value - minimum) / range);
}
bool flash_sort_values(std::int64_t *values, std::size_t length) {
    if (length <= 1) return true;
    const auto [minimum_it, maximum_it] = std::minmax_element(values, values + length);
    const std::int64_t minimum = *minimum_it, maximum = *maximum_it;
    if (minimum == maximum) return true;
    const std::int64_t range = maximum - minimum;
    std::size_t classes = (9 * length) / 20;
    if (classes < 1) classes = 1;
    std::size_t class_ends[MAX_LENGTH] = {};
    for (std::size_t i = 0; i < length; ++i) ++class_ends[class_of(values[i], minimum, range, classes)];
    for (std::size_t i = 1; i < classes; ++i) class_ends[i] += class_ends[i - 1];
    std::size_t moves = 0, j = 0, k = classes - 1;
    while (moves < length - 1) {
        while (j > class_ends[k] - 1) {
            ++j;
            if (j >= length) return false;
            k = class_of(values[j], minimum, range, classes);
        }
        std::int64_t flash = values[j];
        while (j != class_ends[k]) {
            k = class_of(flash, minimum, range, classes);
            const std::size_t target = --class_ends[k];
            const std::int64_t hold = values[target];
            values[target] = flash;
            flash = hold;
            ++moves;
        }
    }
    for (std::size_t i = 1; i < length; ++i) {
        const std::int64_t key = values[i];
        std::size_t cursor = i;
        while (cursor > 0 && values[cursor - 1] > key) { values[cursor] = values[cursor - 1]; --cursor; }
        values[cursor] = key;
    }
    return true;
}
}

extern "C" std::int64_t flash_sort(const std::int64_t *input, std::size_t length,
                                   std::uint8_t *output, std::size_t output_capacity) {
    if (length > 65 || !valid_length(length) || (length != 0 && input == nullptr)) return -1;
    std::int64_t values[MAX_LENGTH] = {};
    for (std::size_t i = 0; i < length; ++i) {
        if (input[i] < -1000000 || input[i] > 1000000) return -1;
        values[i] = input[i];
    }
    const std::size_t output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    if (!flash_sort_values(values, length)) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        const std::uint32_t bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(values[i]));
        for (std::size_t byte = 0; byte < 4; ++byte) output[i * 4 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(output_bytes);
}
