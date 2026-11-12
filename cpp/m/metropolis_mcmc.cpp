#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxStates = 8;
constexpr std::size_t kMaxSteps = 64;
constexpr std::size_t kMaxInput = 140;

bool bounded_integer(double value, double minimum, double maximum) noexcept {
    return std::isfinite(value) && std::trunc(value) == value &&
           value >= minimum && value <= maximum;
}
}

extern "C" std::int64_t metropolis_mcmc(const double* input, std::size_t length,
    double* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > kMaxInput) return -1;
    if (!bounded_integer(input[0], 1.0, static_cast<double>(kMaxStates)) ||
        !bounded_integer(input[1], 0.0, static_cast<double>(kMaxSteps))) return -1;
    const auto states = static_cast<std::size_t>(input[0]);
    const auto steps = static_cast<std::size_t>(input[1]);
    if (!bounded_integer(input[2], 0.0, static_cast<double>(states - 1)) ||
        !std::isfinite(input[3]) || input[3] < 0.001 || input[3] > 1000.0 ||
        length != 4 + states + 2 * steps) return -1;
    for (std::size_t state = 0; state < states; ++state)
        if (!std::isfinite(input[4 + state]) || std::abs(input[4 + state]) > 1'000'000.0) return -1;
    const auto proposal_start = 4 + states;
    const auto uniform_start = proposal_start + steps;
    for (std::size_t step = 0; step < steps; ++step) {
        if (!bounded_integer(input[proposal_start + step], 0.0, static_cast<double>(states - 1)) ||
            !std::isfinite(input[uniform_start + step]) || input[uniform_start + step] < 0.0 ||
            input[uniform_start + step] >= 1.0) return -1;
    }
    if (output == nullptr || capacity < steps + 1) return -2;

    auto current = static_cast<std::size_t>(input[2]);
    output[0] = static_cast<double>(current);
    for (std::size_t step = 0; step < steps; ++step) {
        const auto proposal = static_cast<std::size_t>(input[proposal_start + step]);
        const double delta = (input[4 + proposal] - input[4 + current]) / input[3];
        if (delta <= 0.0) current = proposal;
        else if (input[uniform_start + step] < std::exp(-delta)) current = proposal;
        output[step + 1] = static_cast<double>(current);
    }
    return static_cast<std::int64_t>(steps + 1);
}
