#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
typedef float (*objective_fn)(float);

static float minimum_function(float x) { return x * x - 2.0f * x + 3.0f; }
static float maximum_function(float x) { return -x * x - 2.0f * x + 3.0f; }

static float ternary_min(objective_fn f, float start, float end, float precision)
{
    if (fabsf(end - start) >= precision) {
        const float width = end - start;
        const float mid1 = start + width / 3.0f;
        const float mid2 = end - width / 3.0f;
        const float r1 = f(mid1), r2 = f(mid2);
        if (r1 < r2) return ternary_min(f, start, mid2, precision);
        if (r1 > r2) return ternary_min(f, mid1, end, precision);
        return ternary_min(f, mid1, mid2, precision);
    }
    return f(start);
}

static float ternary_max(objective_fn f, float start, float end, float precision)
{
    if (fabsf(end - start) >= precision) {
        const float width = end - start;
        const float mid1 = start + width / 3.0f;
        const float mid2 = end - width / 3.0f;
        const float r1 = f(mid1), r2 = f(mid2);
        if (r1 < r2) return ternary_max(f, mid1, end, precision);
        if (r1 > r2) return ternary_max(f, start, mid2, precision);
        return ternary_max(f, mid1, mid2, precision);
    }
    return f(start);
}

double ternary_search_min_max_recursive(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t mode = values[0], start_milli = values[1], end_milli = values[2], precision_milli = values[3];
    const int64_t center_milli = mode == 0 ? 1000 : mode == 1 ? -1000 : 0;
    if (mode < 0 || mode > 1 || start_milli < -100000 || end_milli > 100000 ||
        start_milli >= center_milli || end_milli <= center_milli || precision_milli < 1 || precision_milli > 8)
        return INVALID_RESULT;
    const float start = (float)start_milli / 1000.0f;
    const float end = (float)end_milli / 1000.0f;
    const float precision = (float)precision_milli / 1000.0f;
    return (double)(mode == 0 ? ternary_min(minimum_function, start, end, precision)
                              : ternary_max(maximum_function, start, end, precision));
}
