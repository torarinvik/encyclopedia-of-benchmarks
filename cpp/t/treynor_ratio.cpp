// Treynor ratio: (portfolio return - risk-free rate) / beta.
#include <cstddef>
#include <cstdint>

extern "C" double treynor_ratio(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return -1.0e300;
    const std::int64_t portfolio_return = values[0];
    const std::int64_t risk_free_rate = values[1];
    const std::int64_t beta = values[2];
    if (portfolio_return < -1000 || portfolio_return > 1000 ||
        risk_free_rate < -1000 || risk_free_rate > 1000 ||
        beta < -1000 || beta > 1000 || beta == 0) return -1.0e300;
    return static_cast<double>(portfolio_return - risk_free_rate) / static_cast<double>(beta);
}
