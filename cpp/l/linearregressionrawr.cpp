#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t min_sample_count = 2;
constexpr std::size_t max_sample_count = 32;
constexpr std::size_t max_parseable_input_length = 66;
constexpr std::size_t max_output_elements = 2;

bool exact_integer_in_range(double value, int minimum, int maximum) noexcept
{
    if (!std::isfinite(value) || value < static_cast<double>(minimum) ||
        value > static_cast<double>(maximum)) return false;
    return value == static_cast<double>(static_cast<int>(value));
}

double rounded_divide(double numerator, double denominator) noexcept
{
    volatile double result = numerator / denominator;
    return result;
}
} // namespace

extern "C" std::int64_t linearregressionrawr(const double* input,
                                              std::size_t input_length,
                                              double* output,
                                              std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length == 0 ||
        input_length > max_parseable_input_length) return -1;
    for (std::size_t index = 0; index < input_length; ++index) {
        if (!std::isfinite(input[index])) return -1;
    }

    if (!exact_integer_in_range(input[0], static_cast<int>(min_sample_count),
                                static_cast<int>(max_sample_count))) return -1;
    const std::size_t sample_count = static_cast<std::size_t>(input[0]);
    if (input_length != 1 + 2 * sample_count) return -1;

    std::int64_t predictor_sum = 0;
    std::int64_t response_sum = 0;
    std::int64_t cross_product_sum = 0;
    std::int64_t predictor_square_sum = 0;
    std::int64_t first_predictor = 0;
    bool predictors_are_constant = true;
    for (std::size_t index = 0; index < sample_count; ++index) {
        const double predictor_value = input[1 + index];
        const double response_value = input[1 + sample_count + index];
        if (!exact_integer_in_range(predictor_value, -4, 4) ||
            !exact_integer_in_range(response_value, -16, 16)) return -1;

        const std::int64_t predictor = static_cast<std::int64_t>(predictor_value);
        const std::int64_t response = static_cast<std::int64_t>(response_value);
        if (index == 0) first_predictor = predictor;
        else if (predictor != first_predictor) predictors_are_constant = false;

        predictor_sum += predictor;
        response_sum += response;
        cross_product_sum += predictor * response;
        predictor_square_sum += predictor * predictor;
    }
    if (predictor_sum != 0 || predictors_are_constant || predictor_square_sum == 0) return -1;

    const double results[max_output_elements] = {
        rounded_divide(static_cast<double>(response_sum), static_cast<double>(sample_count)),
        rounded_divide(static_cast<double>(cross_product_sum), static_cast<double>(predictor_square_sum))
    };
    if (output == nullptr || output_capacity < max_output_elements) return -2;
    for (std::size_t index = 0; index < max_output_elements; ++index) output[index] = results[index];
    return static_cast<std::int64_t>(max_output_elements);
}
