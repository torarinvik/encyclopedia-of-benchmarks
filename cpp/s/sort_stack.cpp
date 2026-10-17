#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr std::size_t kMaxItems = 64;

void insert_sorted(std::int32_t* stack, std::size_t& size, std::int32_t value) {
    if (size == 0 || value > stack[size - 1]) {
        stack[size++] = value;
        return;
    }
    const auto top = stack[--size];
    insert_sorted(stack, size, value);
    stack[size++] = top;
}

void sort_recursively(std::int32_t* stack, std::size_t& size) {
    if (size == 0) return;
    const auto top = stack[--size];
    sort_recursively(stack, size);
    insert_sorted(stack, size, top);
}
}

extern "C" std::int64_t sort_stack(const std::int64_t* input, std::size_t length,
                                    std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || length < 1 || length > 65) return -1;
    if (input[0] < 0 || input[0] > 64 || length != 1 + static_cast<std::size_t>(input[0])) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    std::int32_t stack[kMaxItems];
    for (std::size_t i = 0; i < count; ++i) {
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
        stack[i] = static_cast<std::int32_t>(input[i + 1]);
    }
    auto size = count;
    sort_recursively(stack, size);
    const auto bytes = size * 4;
    if (output == nullptr || output_capacity < bytes) return -2;
    for (std::size_t i = 0; i < size; ++i) {
        const auto bits = static_cast<std::uint32_t>(stack[i]);
        for (std::size_t b = 0; b < 4; ++b) output[4 * i + b] = static_cast<std::uint8_t>(bits >> (8 * b));
    }
    return static_cast<std::int64_t>(bytes);
}
