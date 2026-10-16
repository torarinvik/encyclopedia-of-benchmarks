#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxMilliValue = 100000;
constexpr std::int64_t kMaxSuccessCount = 20;
constexpr double kInvalidResult = -1.0e300;

double poisson_factorial(double x) noexcept
{
    double factorial = x;
    for (std::int64_t i = static_cast<std::int64_t>(x) - 1; i > 0; --i)
        factorial *= static_cast<double>(i);
    if (factorial <= 0.0) factorial = 1.0;
    return factorial;
}

double poisson_point(double mean, std::int64_t successes) noexcept
{
    return (std::pow(mean, static_cast<double>(successes)) * std::exp(-mean)) /
           poisson_factorial(static_cast<double>(successes));
}
}

extern "C" double poisson_dist(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 4) return kInvalidResult;
    const std::int64_t operation = input[0], first = input[1], second = input[2], third = input[3];
    if (operation == 0) {
        if (first < 0 || first > kMaxMilliValue || second < 1 || second > kMaxMilliValue || third != 0)
            return kInvalidResult;
        return (static_cast<double>(first) / 1000.0) / (static_cast<double>(second) / 1000.0);
    }
    if (operation == 1) {
        if (first < 0 || first > kMaxMilliValue || second < 0 || second > kMaxMilliValue || third != 0)
            return kInvalidResult;
        return (static_cast<double>(first) / 1000.0) * (static_cast<double>(second) / 1000.0);
    }
    if (operation == 2) {
        if (first < 0 || first > kMaxMilliValue || second < 0 || second > kMaxSuccessCount || third != 0)
            return kInvalidResult;
        return poisson_point(static_cast<double>(first) / 1000.0, second);
    }
    if (operation == 3) {
        if (first < 0 || first > kMaxMilliValue || second < 0 || second > third || third > kMaxSuccessCount)
            return kInvalidResult;
        const double mean = static_cast<double>(first) / 1000.0;
        double probability = 0.0;
        for (std::int64_t successes = second; successes <= third; ++successes)
            probability += poisson_point(mean, successes);
        return probability;
    }
    return kInvalidResult;
}
