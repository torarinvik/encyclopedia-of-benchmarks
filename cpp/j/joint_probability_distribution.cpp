#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_support_length = 4;
constexpr std::size_t max_parseable_input_length = 20;
constexpr std::size_t max_output_elements = 48;

bool parse_count(double raw, std::size_t &count)
{
    if (raw != raw || raw < 1.0 || raw > static_cast<double>(max_support_length)) return false;
    const auto parsed = static_cast<std::size_t>(raw);
    if (static_cast<double>(parsed) != raw) return false;
    count = parsed;
    return true;
}

bool parse_support(double raw, std::int64_t &support)
{
    if (raw != raw || raw < -1000.0 || raw > 1000.0) return false;
    const auto parsed = static_cast<std::int64_t>(raw);
    if (static_cast<double>(parsed) != raw) return false;
    support = parsed;
    return true;
}

bool valid_probability(double value)
{
    return value == value && value >= -1000000.0 && value <= 1000000.0;
}
}

extern "C" std::int64_t joint_probability_distribution(
    const double *input, std::size_t input_length,
    double *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 2 || input_length > max_parseable_input_length) return -1;
    std::size_t x_count, y_count;
    if (!parse_count(input[0], x_count) || !parse_count(input[1], y_count)) return -1;
    if (input_length != 2 + 2 * x_count + 2 * y_count) return -1;

    const std::size_t x_start = 2;
    const std::size_t y_start = x_start + x_count;
    const std::size_t x_probability_start = y_start + y_count;
    const std::size_t y_probability_start = x_probability_start + x_count;
    std::int64_t x_values[4], y_values[4];
    double x_probabilities[4], y_probabilities[4];

    for (std::size_t index = 0; index < x_count; ++index) {
        if (!parse_support(input[x_start + index], x_values[index]) ||
            !valid_probability(input[x_probability_start + index])) return -1;
        x_probabilities[index] = input[x_probability_start + index];
        for (std::size_t previous = 0; previous < index; ++previous)
            if (x_values[previous] == x_values[index]) return -1;
    }
    for (std::size_t index = 0; index < y_count; ++index) {
        if (!parse_support(input[y_start + index], y_values[index]) ||
            !valid_probability(input[y_probability_start + index])) return -1;
        y_probabilities[index] = input[y_probability_start + index];
        for (std::size_t previous = 0; previous < index; ++previous)
            if (y_values[previous] == y_values[index]) return -1;
    }

    const auto required = 3 * x_count * y_count;
    if (required > max_output_elements) return -1;
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0;
    for (std::size_t x_index = 0; x_index < x_count; ++x_index) {
        for (std::size_t y_index = 0; y_index < y_count; ++y_index) {
            output[position++] = static_cast<double>(x_values[x_index]);
            output[position++] = static_cast<double>(y_values[y_index]);
            output[position++] = x_probabilities[x_index] * y_probabilities[y_index];
        }
    }
    return static_cast<std::int64_t>(required);
}
