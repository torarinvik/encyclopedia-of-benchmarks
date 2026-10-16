#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MAX_COUNT = 64;
constexpr std::size_t HEAP_CAPACITY = 32;
constexpr std::int64_t VALUE_LIMIT = 1'000'000;

template<bool IsMax>
void heap_push(std::array<std::int64_t, HEAP_CAPACITY>& values, std::size_t& size,
               std::int64_t value) noexcept {
    std::size_t index = size++;
    values[index] = value;
    while (index > 0) {
        const std::size_t parent = (index - 1) / 2;
        const bool ordered = IsMax ? values[parent] >= values[index] : values[parent] <= values[index];
        if (ordered) break;
        std::swap(values[parent], values[index]);
        index = parent;
    }
}

template<bool IsMax>
std::int64_t heap_pop(std::array<std::int64_t, HEAP_CAPACITY>& values,
                      std::size_t& size) noexcept {
    const std::int64_t result = values[0];
    values[0] = values[--size];
    std::size_t index = 0;
    for (;;) {
        const std::size_t left = 2 * index + 1, right = left + 1;
        std::size_t best = index;
        if (left < size && (IsMax ? values[left] > values[best] : values[left] < values[best])) best = left;
        if (right < size && (IsMax ? values[right] > values[best] : values[right] < values[best])) best = right;
        if (best == index) break;
        std::swap(values[index], values[best]);
        index = best;
    }
    return result;
}

void write_f64_le(std::uint8_t* output, std::size_t position, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t median_finder(const std::int64_t* input, std::size_t length,
                                       std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > MAX_COUNT + 1) return -1;
    const std::int64_t count_value = input[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(MAX_COUNT) ||
        length != static_cast<std::size_t>(count_value) + 1) return -1;
    const std::size_t count = static_cast<std::size_t>(count_value);
    for (std::size_t index = 0; index < count; ++index)
        if (input[index + 1] < -VALUE_LIMIT || input[index + 1] > VALUE_LIMIT) return -1;
    const std::size_t required = count * 8;
    if (output == nullptr || output_capacity < required) return -2;

    std::array<std::int64_t, HEAP_CAPACITY> lower{}, upper{};
    std::size_t lower_size = 0, upper_size = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = input[index + 1];
        if (lower_size == HEAP_CAPACITY && lower_size > upper_size && value <= lower[0]) {
            heap_push<false>(upper, upper_size, heap_pop<true>(lower, lower_size));
            heap_push<true>(lower, lower_size, value);
        } else {
            if (lower_size == 0 || value <= lower[0]) heap_push<true>(lower, lower_size, value);
            else heap_push<false>(upper, upper_size, value);
            if (lower_size > upper_size + 1) heap_push<false>(upper, upper_size, heap_pop<true>(lower, lower_size));
            else if (upper_size > lower_size) heap_push<true>(lower, lower_size, heap_pop<false>(upper, upper_size));
        }
        const double median = lower_size == upper_size
            ? (static_cast<double>(lower[0]) + static_cast<double>(upper[0])) / 2.0
            : static_cast<double>(lower[0]);
        write_f64_le(output, index * 8, median);
    }
    return static_cast<std::int64_t>(required);
}
