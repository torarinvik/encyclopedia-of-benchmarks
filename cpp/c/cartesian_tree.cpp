#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 128;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t cartesian_tree(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 1 + kMaxN) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;

    std::array<std::size_t, kMaxN> stack{};
    std::array<std::int64_t, kMaxN> parent{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto key = input[i + 1];
        if (key < 0 || key > 1000000000) return -1;
        parent[i] = static_cast<std::int64_t>(i);
    }

    std::size_t stack_size = 0;
    for (std::size_t i = 0; i < n; ++i) {
        std::size_t last = kMaxN;
        while (stack_size > 0 && input[stack[stack_size - 1] + 1] > input[i + 1])
            last = stack[--stack_size];
        if (stack_size > 0) parent[i] = static_cast<std::int64_t>(stack[stack_size - 1]);
        if (last < kMaxN) parent[last] = static_cast<std::int64_t>(i);
        stack[stack_size++] = i;
    }

    const auto output_bytes = n * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < n; ++i)
        store_i64_le(output, i * 8, parent[i]);
    return static_cast<std::int64_t>(output_bytes);
}
