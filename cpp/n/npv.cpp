/* Net present value with source-ordered binary64 terms. */
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double npv(const std::int64_t *input, std::size_t length) noexcept {
    if (!input || length < 2 || input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 1000 || length != static_cast<std::size_t>(input[0]) + 2) return -1e300;
    const auto n=static_cast<std::size_t>(input[0]);
    for (std::size_t t=0;t<n;++t) if (input[t+2] < -1000000 || input[t+2] > 1000000) return -1e300;
    const double rate=static_cast<double>(input[1])/10000.0;
    double total=0.0;
    for (std::size_t t=0;t<n;++t) {
        const double term=static_cast<double>(input[t+2])/std::pow(1.0+rate,static_cast<double>(t));
        total+=term;
    }
    return total;
}
