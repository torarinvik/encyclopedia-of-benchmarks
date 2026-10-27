#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 3, MAX_OUTPUT_BYTES = 144;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t johnson_trotter_adjacent_gray_code(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length != 1 || input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    std::size_t permutation_count = 1;
    for (std::size_t value = 2; value <= n; ++value) permutation_count *= value;
    const std::size_t output_bytes = 8 * n * permutation_count;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::array<std::int64_t, MAX_N> permutation{};
    std::array<std::int64_t, MAX_N + 1> direction{};
    for (std::size_t index = 0; index < n; ++index) { permutation[index] = static_cast<std::int64_t>(index + 1); direction[index + 1] = -1; }
    std::array<std::uint8_t, MAX_OUTPUT_BYTES> staged{};
    std::size_t rows = 0;
    for (;;) {
        for (std::size_t index = 0; index < n; ++index) store_i64_le(staged.data(), 8 * (rows * n + index), permutation[index]);
        ++rows;
        std::int64_t largest_mobile = 0;
        std::size_t mobile_position = n;
        for (std::size_t position = 0; position < n; ++position) {
            const auto value = permutation[position];
            const auto neighbor = static_cast<std::int64_t>(position) + direction[static_cast<std::size_t>(value)];
            if (neighbor >= 0 && neighbor < static_cast<std::int64_t>(n) && value > permutation[static_cast<std::size_t>(neighbor)] && value > largest_mobile) {
                largest_mobile = value; mobile_position = position;
            }
        }
        if (mobile_position == n) break;
        const auto neighbor = static_cast<std::size_t>(static_cast<std::int64_t>(mobile_position) + direction[static_cast<std::size_t>(largest_mobile)]);
        const auto temporary = permutation[mobile_position]; permutation[mobile_position] = permutation[neighbor]; permutation[neighbor] = temporary;
        for (auto value = largest_mobile + 1; value <= static_cast<std::int64_t>(n); ++value) direction[static_cast<std::size_t>(value)] = -direction[static_cast<std::size_t>(value)];
    }
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
