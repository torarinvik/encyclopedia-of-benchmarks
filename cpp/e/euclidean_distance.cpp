#include <cmath>
#include <cstddef>
#include <cstdint>
static constexpr std::size_t MAX_DIMENSION = 128;
static constexpr double INVALID_RESULT = -1.0e300;

extern "C" double euclidean_distance(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 1) return INVALID_RESULT;
    const std::int64_t dimension = values[0];
    if (dimension < 0 || dimension > static_cast<std::int64_t>(MAX_DIMENSION)
        || length != 1 + 2 * static_cast<std::size_t>(dimension)) return INVALID_RESULT;
    double sum_of_squares = 0.0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(dimension); ++i) {
        const auto first = values[1 + i];
        const auto second = values[1 + static_cast<std::size_t>(dimension) + i];
        if (first < -1'000'000 || first > 1'000'000 || second < -1'000'000 || second > 1'000'000)
            return INVALID_RESULT;
        const double difference = static_cast<double>(first) - static_cast<double>(second);
        sum_of_squares += difference * difference;
    }
    return std::sqrt(sum_of_squares);
}
