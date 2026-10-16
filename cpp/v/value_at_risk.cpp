/* Historical-simulation Value at Risk. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kScale = 1'000'000;
constexpr std::size_t kMaxReturns = 64, kMaxParsedReturns = 65, kMaxInputLength = 67;
constexpr std::int64_t kMaxSample = 1'000'000'000;
constexpr double kInvalidResult = -1.0e300;

void sift_down(double *values, std::size_t root_start, std::size_t end) {
    std::size_t root = root_start;
    while (root < end / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const double temporary = values[root]; values[root] = values[child]; values[child] = temporary;
        root = child;
    }
}

void heap_sort(double *values, std::size_t length) {
    for (std::size_t start = length / 2; start > 0; --start) sift_down(values, start - 1, length);
    for (std::size_t end = length; end > 1; --end) {
        const double temporary = values[0]; values[0] = values[end - 1]; values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}
}

extern "C" double value_at_risk(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return kInvalidResult;
    const auto confidence_micro = input[0], count_value = input[1];
    if (confidence_micro < 1 || confidence_micro >= kScale || count_value < 1 || count_value > static_cast<std::int64_t>(kMaxParsedReturns)) return kInvalidResult;
    if (length != 2 + static_cast<std::size_t>(count_value) || count_value > static_cast<std::int64_t>(kMaxReturns)) return kInvalidResult;
    const auto count = static_cast<std::size_t>(count_value);
    double returns[kMaxReturns];
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = input[2 + i];
        if (value < -kMaxSample || value > kMaxSample) return kInvalidResult;
        returns[i] = static_cast<double>(value) / static_cast<double>(kScale);
    }
    heap_sort(returns, count);
    const double confidence = static_cast<double>(confidence_micro) / static_cast<double>(kScale);
    const double quantile = 1.0 - confidence;
    const double position = static_cast<double>(count - 1) * quantile;
    const auto lower = static_cast<std::size_t>(position);
    const double fraction = position - static_cast<double>(lower);
    const double threshold = lower == count - 1 ? returns[count - 1]
        : returns[lower] * (1.0 - fraction) + returns[lower + 1] * fraction;
    return -threshold;
}
