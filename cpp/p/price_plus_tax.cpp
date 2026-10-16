#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kScale = 1'000'000;
constexpr std::int64_t kMaxPriceMicro = 1'000'000'000'000;
constexpr std::int64_t kMaxTaxRateMicro = 1'000'000;
constexpr std::size_t kMaxInputLength = 3;
constexpr double kInvalidResult = -1.0e300;
}

extern "C" double price_plus_tax(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2 || length > kMaxInputLength) return kInvalidResult;
    const auto price_micro = values[0];
    const auto tax_rate_micro = values[1];
    if (price_micro < 0 || price_micro > kMaxPriceMicro
            || tax_rate_micro < 0 || tax_rate_micro > kMaxTaxRateMicro) return kInvalidResult;
    const double price = static_cast<double>(price_micro) / static_cast<double>(kScale);
    const double tax_rate = static_cast<double>(tax_rate_micro) / static_cast<double>(kScale);
    return price * (1.0 + tax_rate);
}
