#include <cmath>

// Probability of exactly x successes in n Bernoulli trials.
extern "C" double binomial_dist(double n, double p, double x) noexcept {
    double numerator = n;
    double denominator = x;
    for (int i = static_cast<int>(n) - 1;
         i >= (static_cast<int>(n) - static_cast<int>(x) + 1); --i) {
        numerator *= static_cast<double>(i);
    }
    for (int i = 1; i < static_cast<int>(x); ++i) {
        denominator *= static_cast<double>(i);
    }
    return (numerator / denominator) * std::pow(p, x) * std::pow(1.0 - p, n - x);
}
