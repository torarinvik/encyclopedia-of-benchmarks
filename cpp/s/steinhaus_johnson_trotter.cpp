#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxLength = 6;

void emit_row(const std::array<std::int32_t, kMaxLength>& values, std::size_t length,
              std::uint8_t *output, std::size_t& offset) noexcept
{
    for (std::size_t index = 0; index < length; ++index) {
        const auto bits = static_cast<std::uint32_t>(values[index]);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[offset++] = static_cast<std::uint8_t>(bits >> (8U * static_cast<unsigned int>(byte)));
    }
}
}

extern "C" std::int64_t steinhaus_johnson_trotter(const std::int32_t *input,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length == 0 || length > kMaxLength) return -1;
    std::size_t permutations = 1;
    for (std::size_t factor = 2; factor <= length; ++factor) permutations *= factor;
    const std::size_t required = 4 * length * permutations;
    if (output == nullptr || output_capacity < required) return -2;

    std::array<std::int32_t, kMaxLength> values{};
    std::array<std::size_t, kMaxLength> inversion{};
    for (std::size_t index = 0; index < length; ++index) values[index] = input[index];
    std::size_t offset = 0;
    emit_row(values, length, output, offset);

    std::size_t index = 1;
    while (index < length) {
        if (inversion[index] < index) {
            const std::size_t swap_index = index % 2 == 0 ? 0 : inversion[index];
            const std::int32_t temporary = values[swap_index];
            values[swap_index] = values[index];
            values[index] = temporary;
            emit_row(values, length, output, offset);
            ++inversion[index];
            index = 1;
        } else {
            inversion[index] = 0;
            ++index;
        }
    }
    return static_cast<std::int64_t>(required);
}
