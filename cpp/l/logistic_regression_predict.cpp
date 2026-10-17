#include <cstddef>
#include <cstdint>

extern "C" std::int64_t logistic_regression_predict(const std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 2051) return -1;
    const auto rows = values[0], features = values[1];
    if (rows < 1 || rows > 63 || features < 1 || features > 32 ||
        length != 2u + static_cast<std::size_t>(rows * features + features)) return -1;
    const auto theta_offset = 2u + static_cast<std::size_t>(rows * features);
    for (std::size_t i = 0; i < static_cast<std::size_t>(rows * features + features); ++i)
        if (values[2 + i] < -1000 || values[2 + i] > 1000) return -1;
    std::uint64_t mask = 0;
    for (std::size_t row = 0; row < static_cast<std::size_t>(rows); ++row) {
        std::int64_t score = 0;
        for (std::size_t feature = 0; feature < static_cast<std::size_t>(features); ++feature)
            score += values[2 + row * static_cast<std::size_t>(features) + feature] * values[theta_offset + feature];
        if (score >= 0) mask |= std::uint64_t{1} << row;
    }
    return static_cast<std::int64_t>(mask);
}
