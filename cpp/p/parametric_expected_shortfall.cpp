#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;
constexpr std::size_t max_parseable_input_length = 69;
constexpr double pi_value = 3.14159265358979323846264338327950288;

double qnorm_r_as241(double probability) noexcept
{
    const double q = probability - 0.5;
    if (std::fabs(q) <= 0.425) {
        const double r = 0.180625 - q * q;
        const double numerator = (((((((
            2509.0809287301226727 * r + 33430.575583588128105) * r + 67265.770927008700853) * r +
            45921.953931549871457) * r + 13731.693765509461125) * r + 1971.5909503065514427) * r +
            133.14166789178437745) * r + 3.387132872796366608);
        const double denominator = (((((((
            5226.495278852854561 * r + 28729.085735721942674) * r + 39307.89580009271061) * r +
            21213.794301586595867) * r + 5394.1960214247511077) * r + 687.1870074920579083) * r +
            42.313330701600911252) * r + 1.0);
        return q * numerator / denominator;
    }
    const double r = std::sqrt(-std::log(1.0 - probability)) - 1.6;
    const double numerator = (((((((
        0.00077454501427834140764 * r + 0.0227238449892691845833) * r +
        0.24178072517745061177) * r + 1.27045825245236838258) * r +
        3.64784832476320460504) * r + 5.7694972214606914055) * r +
        4.6303378461565452959) * r + 1.42343711074968357734);
    const double denominator = (((((((
        1.05075007164441684324e-9 * r + 0.0005475938084995344946) * r +
        0.0151986665636164571966) * r + 0.14810397642748007459) * r +
        0.68976733498510000455) * r + 1.6763848301838038494) * r +
        2.05319162663775882187) * r + 1.0);
    return numerator / denominator;
}
}

extern "C" std::int64_t calculate_es_parametric(const double *input, std::size_t input_length,
                                                  double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 24 || input_length > max_parseable_input_length)
        return invalid_result;
    for (std::size_t i = 0; i < input_length; ++i)
        if (!std::isfinite(input[i])) return invalid_result;

    const double portfolio_value = input[0];
    const double confidence_level = input[1];
    const double time_horizon = input[2];
    const double count_value = input[3];
    if (count_value < 20.0 || count_value > 64.0 || std::floor(count_value) != count_value)
        return invalid_result;
    const auto return_count = static_cast<std::size_t>(count_value);
    if (input_length != 4 + return_count || portfolio_value < 100.0 ||
        portfolio_value > 1000000.0 || confidence_level < 0.5 || confidence_level > 0.95 ||
        time_horizon < 1.0 || time_horizon > 10.0)
        return invalid_result;

    double returns[64];
    for (std::size_t i = 0; i < return_count; ++i) {
        returns[i] = input[4 + i];
        if (returns[i] < -0.25 || returns[i] > 0.25) return invalid_result;
    }
    if (output == nullptr || output_capacity < 1) return output_error;

    double sum = 0.0;
    for (std::size_t i = 0; i < return_count; ++i) sum += returns[i];
    const double mean = sum / static_cast<double>(return_count);
    double squared_deviations = 0.0;
    for (std::size_t i = 0; i < return_count; ++i) {
        const double difference = returns[i] - mean;
        squared_deviations += difference * difference;
    }
    const double sample_sd = std::sqrt(squared_deviations / static_cast<double>(return_count - 1));
    const double z = qnorm_r_as241(confidence_level);
    const double density = std::exp(-z * z / 2.0) / std::sqrt(2.0 * pi_value);
    const double lambda = density / (1.0 - confidence_level);
    const double result = portfolio_value * (lambda * sample_sd - mean) * std::sqrt(time_horizon);
    output[0] = result;
    return 1;
}
