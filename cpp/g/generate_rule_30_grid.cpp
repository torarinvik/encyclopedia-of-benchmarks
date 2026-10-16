#include <cstddef>
#include <cstdint>

extern "C" std::int64_t generate_rule_30_grid(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output,
                                                std::size_t output_capacity) noexcept {
    constexpr std::size_t max_width = 64;
    constexpr std::size_t max_generations = 64;
    if (input == nullptr || length != 2) return -1;
    const auto width_value = input[0];
    const auto generations_value = input[1];
    if (width_value < 1 || width_value > static_cast<std::int64_t>(max_width) ||
        generations_value < 1 || generations_value > static_cast<std::int64_t>(max_generations)) return -1;
    const auto width = static_cast<std::size_t>(width_value);
    const auto generations = static_cast<std::size_t>(generations_value);
    const std::size_t output_count = width * generations;
    if (output_capacity < output_count || output == nullptr) return -2;

    std::int64_t current[max_width] = {};
    std::int64_t next[max_width] = {};
    current[width / 2] = 1;
    for (std::size_t column = 0; column < width; ++column)
        output[column] = static_cast<std::uint8_t>(current[column]);
    for (std::size_t generation = 1; generation < generations; ++generation) {
        for (std::size_t column = 0; column < width; ++column) {
            const auto left = column > 0 ? current[column - 1] : 0;
            const auto right = column + 1 < width ? current[column + 1] : 0;
            const unsigned pattern = static_cast<unsigned>(left * 4 + current[column] * 2 + right);
            next[column] = (30u >> pattern) & 1u;
        }
        for (std::size_t column = 0; column < width; ++column) {
            current[column] = next[column];
            output[generation * width + column] = static_cast<std::uint8_t>(next[column]);
        }
    }
    return static_cast<std::int64_t>(output_count);
}
