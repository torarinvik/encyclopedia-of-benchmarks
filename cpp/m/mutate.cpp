#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" int64_t mutate(const double *input, size_t length, double *output, size_t capacity)
{
    if (input == nullptr || length < 2 || length > 130) return -1;
    const double mu = input[0], count_value = input[1];
    if (!std::isfinite(mu) || mu < 0.0 || mu > 1.0 || !std::isfinite(count_value) ||
        std::floor(count_value) != count_value || count_value < 0.0 || count_value > 64.0) return -1;
    const size_t count = static_cast<size_t>(count_value);
    if (length != 2 + 2 * count) return -1;
    for (size_t index = 0; index < count; ++index) {
        const double gene = input[2 + index];
        if (gene != 0.0 && gene != 1.0) return -1;
    }
    for (size_t index = 0; index < count; ++index) {
        const double draw = input[2 + count + index];
        if (!std::isfinite(draw) || draw < 0.0 || draw >= 1.0) return -1;
    }
    if (output == nullptr || capacity < count) return -2;
    for (size_t index = 0; index < count; ++index) {
        const double gene = input[2 + index];
        const double draw = input[2 + count + index];
        output[index] = draw < mu ? 1.0 - gene : gene;
    }
    return static_cast<int64_t>(count);
}
