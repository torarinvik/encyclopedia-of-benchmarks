#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_steps = 32;
constexpr std::size_t max_input_values = max_steps + 1;
constexpr std::size_t max_output_bytes = max_steps * 8;

void store_i64_le(std::array<std::uint8_t, max_output_bytes>& output,
                  std::size_t offset, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t stormer_verlet_position(const std::int64_t *input,
                                                 std::size_t length,
                                                 std::uint8_t *output,
                                                 std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 3 || length > max_input_values) return -1;
    const auto count_value = input[0];
    if (count_value < 2 || count_value > static_cast<std::int64_t>(max_steps)) return -1;
    if (length != static_cast<std::size_t>(count_value) + 1) return -1;
    if (input[1] < -1024 || input[1] > 1024 || input[2] < -1024 || input[2] > 1024)
        return -1;
    const auto count = static_cast<std::size_t>(count_value);
    for (std::size_t step = 0; step < count - 2; ++step)
        if (input[3 + step] < -64 || input[3 + step] > 64) return -1;

    const auto byte_count = 8 * count;
    if (output == nullptr || output_capacity < byte_count) return -2;
    std::array<std::uint8_t, max_output_bytes> staged{};
    auto previous = input[1];
    auto current = input[2];
    store_i64_le(staged, 0, previous);
    store_i64_le(staged, 8, current);
    for (std::size_t index = 2; index < count; ++index) {
        const auto next = 2 * current - previous + input[index + 1];
        store_i64_le(staged, 8 * index, next);
        previous = current;
        current = next;
    }
    for (std::size_t byte = 0; byte < byte_count; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(byte_count);
}
