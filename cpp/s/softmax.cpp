#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t softmax(const double *values, std::size_t length,
                                double *output, std::size_t capacity) {
    if (values == nullptr || length == 0 || length > 64) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        if (!std::isfinite(values[i]) || values[i] < -20.0 || values[i] > 20.0) return -1;
    }
    if (output == nullptr || capacity < length) return -2;

    double total = 0.0;
    for (std::size_t i = 0; i < length; ++i) total += std::exp(values[i]);
    for (std::size_t i = 0; i < length; ++i) output[i] = std::exp(values[i]) / total;
    return static_cast<std::int64_t>(length);
}
