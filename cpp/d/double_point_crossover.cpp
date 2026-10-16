#include <cstddef>
#include <cstdint>

static void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t double_point_crossover(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 7 || length > 131) return -1;
    const auto n = input[0], j1 = input[1], j2 = input[2];
    if (n < 2 || n > 64 || length != static_cast<std::size_t>(3 + 2 * n) || j1 < 1 || j1 >= j2 || j2 > n) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(2 * n); ++i) if (input[3 + i] < INT64_C(-2147483648) || input[3 + i] > INT64_C(2147483647)) return -1;
    const auto count = static_cast<std::size_t>(n), bytes = 16 * static_cast<std::size_t>(n);
    if (output == nullptr || capacity < bytes) return -2;
    const auto a = static_cast<std::size_t>(j1), b = static_cast<std::size_t>(j2);
    for (std::size_t i = 0; i < count; ++i) {
        const auto child1 = (i < a || i >= b) ? input[3 + i] : input[3 + count + i];
        const auto child2 = (i < a || i >= b) ? input[3 + count + i] : input[3 + i];
        put_i64_le(output, i * 8, child1); put_i64_le(output, (count + i) * 8, child2);
    }
    return static_cast<std::int64_t>(bytes);
}
