#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TARGET = 8;

std::size_t required_bytes(std::size_t remaining, std::size_t depth)
{
    if (remaining == 0) return depth + 1;
    std::size_t total = 0;
    const std::size_t maximum_face = remaining < 6 ? remaining : 6;
    for (std::size_t face = 1; face <= maximum_face; ++face)
        total += required_bytes(remaining - face, depth + 1);
    return total;
}

void emit_combinations(std::size_t remaining, std::size_t depth, std::uint8_t *digits,
                       std::uint8_t *output, std::size_t &position)
{
    if (remaining == 0) {
        for (std::size_t index = 0; index < depth; ++index) output[position++] = digits[index];
        output[position++] = static_cast<std::uint8_t>('\n');
        return;
    }
    const std::size_t maximum_face = remaining < 6 ? remaining : 6;
    for (std::size_t face = 1; face <= maximum_face; ++face) {
        digits[depth] = static_cast<std::uint8_t>('0' + face);
        emit_combinations(remaining - face, depth + 1, digits, output, position);
    }
}
}

extern "C" std::int64_t dice_thrower(const std::int64_t *values, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length != 1 || values[0] < 0 || values[0] > MAX_TARGET) return -1;
    const auto target = static_cast<std::size_t>(values[0]);
    const std::size_t needed = required_bytes(target, 0);
    if (output_capacity < needed || output == nullptr) return -2;
    std::uint8_t digits[MAX_TARGET]{};
    std::size_t position = 0;
    emit_combinations(target, 0, digits, output, position);
    return static_cast<std::int64_t>(position);
}
