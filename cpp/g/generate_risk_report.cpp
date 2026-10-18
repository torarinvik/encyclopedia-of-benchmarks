#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;
constexpr std::size_t max_input_length = 69;
constexpr double pi_value = 3.14159265358979323846264338327950288;

double qnorm_r_as241(double probability)
{
    const double q = probability - 0.5;
    if (std::abs(q) <= 0.425) {
        const double r = 0.180625 - q * q;
        double numerator = 2509.0809287301226727;
        numerator = numerator * r + 33430.575583588128105;
        numerator = numerator * r + 67265.770927008700853;
        numerator = numerator * r + 45921.953931549871457;
        numerator = numerator * r + 13731.693765509461125;
        numerator = numerator * r + 1971.5909503065514427;
        numerator = numerator * r + 133.14166789178437745;
        numerator = numerator * r + 3.387132872796366608;
        double denominator = 5226.495278852854561;
        denominator = denominator * r + 28729.085735721942674;
        denominator = denominator * r + 39307.89580009271061;
        denominator = denominator * r + 21213.794301586595867;
        denominator = denominator * r + 5394.1960214247511077;
        denominator = denominator * r + 687.1870074920579083;
        denominator = denominator * r + 42.313330701600911252;
        denominator = denominator * r + 1.0;
        return q * numerator / denominator;
    }
    const double r = std::sqrt(-std::log(1.0 - probability)) - 1.6;
    double numerator = 0.00077454501427834140764;
    numerator = numerator * r + 0.0227238449892691845833;
    numerator = numerator * r + 0.24178072517745061177;
    numerator = numerator * r + 1.27045825245236838258;
    numerator = numerator * r + 3.64784832476320460504;
    numerator = numerator * r + 5.7694972214606914055;
    numerator = numerator * r + 4.6303378461565452959;
    numerator = numerator * r + 1.42343711074968357734;
    double denominator = 1.05075007164441684324e-9;
    denominator = denominator * r + 0.0005475938084995344946;
    denominator = denominator * r + 0.0151986665636164571966;
    denominator = denominator * r + 0.14810397642748007459;
    denominator = denominator * r + 0.68976733498510000455;
    denominator = denominator * r + 1.6763848301838038494;
    denominator = denominator * r + 2.05319162663775882187;
    denominator = denominator * r + 1.0;
    return numerator / denominator;
}
}

extern "C" std::int64_t generate_risk_report(const double *input, std::size_t input_length,
                                               double *output, std::size_t capacity) noexcept
{
    if (input == nullptr || input_length < 24 || input_length > max_input_length) return invalid_result;
    for (std::size_t i = 0; i < input_length; ++i) if (!std::isfinite(input[i])) return invalid_result;
    const double portfolio = input[0], confidence = input[1], horizon = input[2], count_value = input[3];
    if (count_value < 20.0 || count_value > 64.0 || std::floor(count_value) != count_value) return invalid_result;
    const auto count = static_cast<std::size_t>(count_value);
    if (input_length != 4 + count || portfolio < 100.0 || portfolio > 1000000.0 ||
        confidence < 0.5 || confidence > 0.95 || horizon < 1.0 || horizon > 10.0) return invalid_result;
    double returns[64];
    double sum = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        returns[i] = input[4 + i];
        if (returns[i] < -0.25 || returns[i] > 0.25) return invalid_result;
        sum += returns[i];
    }
    const double mean = sum / static_cast<double>(count);
    double squared_deviations = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        const double difference = returns[i] - mean;
        squared_deviations += difference * difference;
    }
    const double sample_sd = std::sqrt(squared_deviations / static_cast<double>(count - 1));
    if (sample_sd == 0.0) return invalid_result;
    const auto tail_count = static_cast<std::size_t>(std::floor((1.0 - confidence) * static_cast<double>(count)));
    if (tail_count < 1) return invalid_result;
    for (std::size_t i = 1; i < count; ++i) {
        const double value = returns[i];
        std::size_t position = i;
        while (position > 0 && returns[position - 1] > value) {
            returns[position] = returns[position - 1];
            --position;
        }
        returns[position] = value;
    }
    double tail_sum = 0.0;
    for (std::size_t i = 0; i < tail_count; ++i) tail_sum += returns[i];
    const double scale = std::sqrt(horizon);
    const double z = qnorm_r_as241(confidence);
    const double es_multiplier = std::exp(-0.5 * z * z) / std::sqrt(2.0 * pi_value) / (1.0 - confidence);
    double third_moment = 0.0, fourth_moment = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        const double difference = returns[i] - mean;
        const double square = difference * difference;
        third_moment += square * difference;
        fourth_moment += square * square;
    }
    third_moment /= static_cast<double>(count);
    fourth_moment /= static_cast<double>(count);
    const double result[8] = {
        -returns[tail_count - 1] * portfolio * scale,
        -(tail_sum / static_cast<double>(tail_count)) * portfolio * scale,
        portfolio * (z * sample_sd - mean) * scale,
        portfolio * (es_multiplier * sample_sd - mean) * scale,
        mean,
        sample_sd,
        third_moment / (sample_sd * sample_sd * sample_sd),
        fourth_moment / (sample_sd * sample_sd * sample_sd * sample_sd) - 3.0,
    };
    if (output == nullptr || capacity < 8) return output_error;
    for (std::size_t i = 0; i < 8; ++i) output[i] = result[i];
    return 8;
}
