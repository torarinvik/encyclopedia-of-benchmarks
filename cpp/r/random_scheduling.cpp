#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_task_count = 32;
constexpr std::size_t max_input_length = 35;
constexpr std::size_t max_output_bytes = 256;
constexpr std::uint64_t java_multiplier = UINT64_C(0x5DEECE66D);
constexpr std::uint64_t java_addend = UINT64_C(0xB);
constexpr std::uint64_t java_mask = UINT64_C(0xFFFFFFFFFFFF);

struct JavaRandom { std::uint64_t state; };

std::uint32_t java_next_bits(JavaRandom &random, unsigned int bits) noexcept
{
    random.state = (random.state * java_multiplier + java_addend) & java_mask;
    return static_cast<std::uint32_t>(random.state >> (48u - bits));
}

std::uint32_t java_next_int(JavaRandom &random, std::uint32_t bound) noexcept
{
    if ((bound & (bound - 1u)) == 0u)
        return static_cast<std::uint32_t>((static_cast<std::uint64_t>(bound) * java_next_bits(random, 31u)) >> 31u);
    for (;;) {
        const auto bits = java_next_bits(random, 31u);
        const auto value = bits % bound;
        if (static_cast<std::uint64_t>(bits) - value + (bound - 1u) <= INT32_MAX) return value;
    }
}

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & UINT64_C(0xff));
        bits >>= 8;
    }
}
}

extern "C" std::int64_t random_scheduling(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    if (input[1] < 0 || input[1] > static_cast<std::int64_t>(max_task_count)) return -1;
    const auto count = static_cast<std::size_t>(input[1]);
    if (length != 2 + count) return -1;

    std::array<std::int64_t, max_task_count> tasks{};
    for (std::size_t index = 0; index < count; ++index) {
        if (input[index + 2] < INT32_MIN || input[index + 2] > INT32_MAX) return -1;
        tasks[index] = input[index + 2];
    }
    JavaRandom random{(static_cast<std::uint64_t>(input[0]) ^ java_multiplier) & java_mask};
    for (std::size_t size = count; size > 1; --size) {
        const auto selected = static_cast<std::size_t>(java_next_int(random, static_cast<std::uint32_t>(size)));
        const auto saved = tasks[size - 1];
        tasks[size - 1] = tasks[selected];
        tasks[selected] = saved;
    }

    const auto output_bytes = count * 8;
    if (output_bytes > max_output_bytes) return -1;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < count; ++index) write_i64_le(output, index * 8, tasks[index]);
    return static_cast<std::int64_t>(output_bytes);
}
