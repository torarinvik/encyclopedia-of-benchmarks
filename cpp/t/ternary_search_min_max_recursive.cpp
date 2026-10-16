#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
using objective_fn = float (*)(float);
float minimum_function(float x) { return x * x - 2.0f * x + 3.0f; }
float maximum_function(float x) { return -x * x - 2.0f * x + 3.0f; }
float ternary_min(objective_fn f, float start, float end, float precision) {
    if (std::fabs(end - start) >= precision) {
        const float width = end - start;
        const float mid1 = start + width / 3.0f, mid2 = end - width / 3.0f;
        const float r1 = f(mid1), r2 = f(mid2);
        if (r1 < r2) return ternary_min(f, start, mid2, precision);
        if (r1 > r2) return ternary_min(f, mid1, end, precision);
        return ternary_min(f, mid1, mid2, precision);
    }
    return f(start);
}
float ternary_max(objective_fn f, float start, float end, float precision) {
    if (std::fabs(end - start) >= precision) {
        const float width = end - start;
        const float mid1 = start + width / 3.0f, mid2 = end - width / 3.0f;
        const float r1 = f(mid1), r2 = f(mid2);
        if (r1 < r2) return ternary_max(f, mid1, end, precision);
        if (r1 > r2) return ternary_max(f, start, mid2, precision);
        return ternary_max(f, mid1, mid2, precision);
    }
    return f(start);
}
}

extern "C" double ternary_search_min_max_recursive(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length != 4) return invalid_result;
    const auto mode = values[0], start_milli = values[1], end_milli = values[2], precision_milli = values[3];
    const std::int64_t center_milli = mode == 0 ? 1000 : mode == 1 ? -1000 : 0;
    if (mode < 0 || mode > 1 || start_milli < -100000 || end_milli > 100000 ||
        start_milli >= center_milli || end_milli <= center_milli || precision_milli < 1 || precision_milli > 8)
        return invalid_result;
    const float start = static_cast<float>(start_milli) / 1000.0f;
    const float end = static_cast<float>(end_milli) / 1000.0f;
    const float precision = static_cast<float>(precision_milli) / 1000.0f;
    return static_cast<double>(mode == 0 ? ternary_min(minimum_function, start, end, precision)
                                         : ternary_max(maximum_function, start, end, precision));
}
