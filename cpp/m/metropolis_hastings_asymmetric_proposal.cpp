#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxStates = 8;
constexpr std::size_t kMaxSteps = 64;
constexpr std::size_t kMaxInput = 267;
constexpr std::size_t kMaxOutput = 65;
}

extern "C" std::int64_t metropolis_hastings_asymmetric_proposal(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 3 || length > kMaxInput) return -1;
    const std::int64_t n64 = input[0], steps64 = input[1], initial64 = input[2];
    if (n64 < 2 || n64 > static_cast<std::int64_t>(kMaxStates) || steps64 < 0 ||
        steps64 > static_cast<std::int64_t>(kMaxSteps) || initial64 < 0 || initial64 >= n64)
        return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto steps = static_cast<std::size_t>(steps64);
    const std::size_t weights_start = 3;
    const std::size_t matrix_start = weights_start + n;
    const std::size_t proposal_start = matrix_start + n * n;
    const std::size_t draw_start = proposal_start + steps;
    if (length != draw_start + 2 * steps) return -1;

    for (std::size_t state = 0; state < n; ++state) {
        const auto weight = input[weights_start + state];
        if (weight < 1 || weight > 1024) return -1;
    }
    for (std::size_t source = 0; source < n; ++source) {
        std::int64_t row_sum = 0;
        for (std::size_t dest = 0; dest < n; ++dest) {
            const auto q = input[matrix_start + source * n + dest];
            if (q < 0 || q > 1024) return -1;
            row_sum += q;
        }
        if (row_sum != 1024) return -1;
    }

    std::uint8_t trace[kMaxOutput]{};
    auto current = static_cast<std::size_t>(initial64);
    trace[0] = static_cast<std::uint8_t>(current);
    for (std::size_t step = 0; step < steps; ++step) {
        const auto proposal64 = input[proposal_start + step];
        const auto draw_num = input[draw_start + 2 * step];
        const auto draw_den = input[draw_start + 2 * step + 1];
        if (proposal64 < 0 || proposal64 >= n64 || draw_den < 1 || draw_den > 1024 ||
            draw_num < 0 || draw_num >= draw_den) return -1;
        const auto proposal = static_cast<std::size_t>(proposal64);
        const auto forward = input[matrix_start + current * n + proposal];
        if (forward == 0) return -1;
        const auto reverse = input[matrix_start + proposal * n + current];
        const auto numerator = input[weights_start + proposal] * reverse;
        const auto denominator = input[weights_start + current] * forward;
        if (numerator >= denominator || draw_num * denominator < draw_den * numerator)
            current = proposal;
        trace[step + 1] = static_cast<std::uint8_t>(current);
    }

    const std::size_t needed = steps + 1;
    if (output == nullptr || capacity < needed) return -2;
    for (std::size_t i = 0; i < needed; ++i) output[i] = trace[i];
    return static_cast<std::int64_t>(needed);
}
