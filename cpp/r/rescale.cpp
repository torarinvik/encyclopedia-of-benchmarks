#include <cstddef>
#include <cstdint>

extern "C" std::int64_t rescale(const std::int64_t *input, std::size_t length) noexcept
{
    constexpr std::int64_t max_draws = 256;
    constexpr std::size_t max_input_length = 260;
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    const std::int64_t max_value = input[0];
    const std::int64_t new_max = input[1];
    const std::int64_t draw_count = input[2];
    if (max_value < 2 || max_value > 64 || new_max < 1 || new_max > 256
        || draw_count < 1 || draw_count > max_draws) return -1;
    if (length != static_cast<std::size_t>(3 + draw_count)) return -1;
    for (std::int64_t i = 0; i < draw_count; ++i) {
        const std::int64_t draw = input[3 + static_cast<std::size_t>(i)];
        if (draw < 0 || draw >= max_value) return -1;
    }

    std::size_t cursor = 0;
    if (new_max == max_value) return input[3];

    if (new_max < max_value) {
        const std::int64_t threshold = max_value - max_value % new_max;
        while (cursor < static_cast<std::size_t>(draw_count)) {
            const std::int64_t draw = input[3 + cursor++];
            if (draw < threshold) return draw % new_max;
        }
        return -1;
    }

    std::int64_t result = 0;
    std::int64_t power = 1;
    while (power < new_max) {
        if (cursor >= static_cast<std::size_t>(draw_count)) return -1;
        result += power * input[3 + cursor++];
        power *= max_value;
    }
    if (power == new_max) return result;

    const std::int64_t threshold = power - power % new_max;
    while (result >= threshold) {
        result = 0;
        power = 1;
        while (power < new_max) {
            if (cursor >= static_cast<std::size_t>(draw_count)) return -1;
            result += power * input[3 + cursor++];
            power *= max_value;
        }
    }
    return result % new_max;
}
