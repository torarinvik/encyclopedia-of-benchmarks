module ternary_search_min_max_recursive;

const double INVALID_RESULT = -1.0e300;
extern fn float fabsf(float value);

fn float minimum_function(float x) { return x * x - 2.0f * x + 3.0f; }
fn float maximum_function(float x) { return -x * x - 2.0f * x + 3.0f; }
fn float ternary_min(float start, float end, float precision) {
    if (fabsf(end - start) >= precision) {
        float width = end - start;
        float mid1 = start + width / 3.0f;
        float mid2 = end - width / 3.0f;
        float r1 = minimum_function(mid1), r2 = minimum_function(mid2);
        if (r1 < r2) return ternary_min(start, mid2, precision);
        if (r1 > r2) return ternary_min(mid1, end, precision);
        return ternary_min(mid1, mid2, precision);
    }
    return minimum_function(start);
}
fn float ternary_max(float start, float end, float precision) {
    if (fabsf(end - start) >= precision) {
        float width = end - start;
        float mid1 = start + width / 3.0f;
        float mid2 = end - width / 3.0f;
        float r1 = maximum_function(mid1), r2 = maximum_function(mid2);
        if (r1 < r2) return ternary_max(mid1, end, precision);
        if (r1 > r2) return ternary_max(start, mid2, precision);
        return ternary_max(mid1, mid2, precision);
    }
    return maximum_function(start);
}

fn double ternary_search_min_max_recursive(long* values, usz length) @export("ternary_search_min_max_recursive") {
    if (values == null || length != 4) return INVALID_RESULT;
    long mode = values[0], start_milli = values[1], end_milli = values[2], precision_milli = values[3];
    long center_milli = mode == 0 ? 1000 : mode == 1 ? -1000 : 0;
    if (mode < 0 || mode > 1 || start_milli < -100000 || end_milli > 100000 ||
        start_milli >= center_milli || end_milli <= center_milli || precision_milli < 1 || precision_milli > 8)
        return INVALID_RESULT;
    float start = (float)start_milli / 1000.0f;
    float end = (float)end_milli / 1000.0f;
    float precision = (float)precision_milli / 1000.0f;
    return (double)(mode == 0 ? ternary_min(start, end, precision)
                              : ternary_max(start, end, precision));
}
