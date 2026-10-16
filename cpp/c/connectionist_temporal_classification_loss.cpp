#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TIME = 32, MAX_CLASSES = 16, MAX_TARGET = 16, MAX_STATES = 33;
constexpr std::size_t MAX_INPUT_LENGTH = 3 + MAX_TARGET + MAX_TIME * MAX_CLASSES;
constexpr double INVALID_RESULT = -1.0e300;
double logaddexp_value(double left, double right) noexcept {
    if (std::isinf(left) && left < 0.0) return right;
    if (std::isinf(right) && right < 0.0) return left;
    const double larger = left > right ? left : right;
    const double smaller = left > right ? right : left;
    return larger + std::log1p(std::exp(smaller - larger));
}
}

extern "C" double connectionist_temporal_classification_loss(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const std::int64_t tv = values[0], cv = values[1], uv = values[2];
    if (tv < 1 || tv > MAX_TIME || cv < 2 || cv > MAX_CLASSES || uv < 1 || uv > MAX_TARGET) return INVALID_RESULT;
    const std::size_t time = static_cast<std::size_t>(tv), classes = static_cast<std::size_t>(cv), target_length = static_cast<std::size_t>(uv);
    const std::size_t probability_base = 3 + target_length;
    if (length != probability_base + time * classes) return INVALID_RESULT;
    std::size_t repeated = 0;
    for (std::size_t i = 0; i < target_length; ++i) {
        const std::int64_t target = values[3 + i];
        if (target < 1 || static_cast<std::size_t>(target) >= classes) return INVALID_RESULT;
        if (i > 0 && target == values[3 + i - 1]) ++repeated;
    }
    if (time < target_length + repeated) return INVALID_RESULT;
    for (std::size_t t = 0; t < time; ++t) {
        std::int64_t sum = 0;
        for (std::size_t c = 0; c < classes; ++c) {
            const std::int64_t p = values[probability_base + t * classes + c];
            if (p < 1 || p > 1000000) return INVALID_RESULT;
            sum += p;
        }
        if (sum != 1000000) return INVALID_RESULT;
    }
    const std::size_t states = 2 * target_length + 1;
    std::int64_t extended[MAX_STATES];
    double previous[MAX_STATES], current[MAX_STATES];
    for (std::size_t s = 0; s < states; ++s) {
        extended[s] = s % 2 == 0 ? 0 : values[3 + s / 2];
        previous[s] = -INFINITY;
    }
    previous[0] = std::log(static_cast<double>(values[probability_base]) / 1000000.0);
    previous[1] = std::log(static_cast<double>(values[probability_base + static_cast<std::size_t>(extended[1])]) / 1000000.0);
    for (std::size_t t = 1; t < time; ++t) {
        for (std::size_t s = 0; s < states; ++s) {
            double incoming = previous[s];
            if (s > 0) incoming = logaddexp_value(incoming, previous[s - 1]);
            if (s > 1 && extended[s] != extended[s - 2]) incoming = logaddexp_value(incoming, previous[s - 2]);
            const double p = static_cast<double>(values[probability_base + t * classes + static_cast<std::size_t>(extended[s])]) / 1000000.0;
            current[s] = incoming + std::log(p);
        }
        for (std::size_t s = 0; s < states; ++s) previous[s] = current[s];
    }
    return -logaddexp_value(previous[states - 1], previous[states - 2]);
}
