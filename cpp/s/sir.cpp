#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t INVALID_RESULT = -1;
constexpr std::int64_t OUTPUT_ERROR = -2;
constexpr std::size_t INPUT_LENGTH = 6;
constexpr std::size_t MAX_PARSEABLE_INPUT_LENGTH = 7;

bool in_range(double value, double minimum, double maximum) noexcept
{
    return value >= minimum && value <= maximum;
}
}

extern "C" std::int64_t sir(const double *input, std::size_t input_length,
                             double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < INPUT_LENGTH || input_length > MAX_PARSEABLE_INPUT_LENGTH)
        return INVALID_RESULT;
    if (input_length != INPUT_LENGTH) return INVALID_RESULT;

    const double s = input[0];
    const double i = input[1];
    const double r = input[2];
    const double beta = input[3];
    const double k = input[4];
    const double time = input[5];
    if (!in_range(s, 0.0, 1000000.0) || !in_range(i, 0.0, 1000000.0) ||
        !in_range(r, 0.0, 1000000.0) || !in_range(beta, 0.0, 0.001) ||
        !in_range(k, 0.0, 1.0) || !in_range(time, 0.0, 140.0))
        return INVALID_RESULT;

    const double d_s = ((-beta) * s) * i;
    const double d_i_infection = (beta * s) * i;
    const double d_i_recovery = k * i;
    const double d_i = d_i_infection - d_i_recovery;
    const double d_r = k * i;

    if (output == nullptr || output_capacity < 3) return OUTPUT_ERROR;
    output[0] = d_s;
    output[1] = d_i;
    output[2] = d_r;
    return 3;
}
