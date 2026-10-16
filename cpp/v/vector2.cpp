#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" int64_t vector2(const double *values, std::size_t length,
                            double *output, std::size_t capacity) {
    if (values == nullptr || length != 6) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (!std::isfinite(values[i])) return -1;
    if (values[0] < 0.0 || values[0] > 10.0 || std::floor(values[0]) != values[0]) return -1;
    for (std::size_t i = 1; i <= 4; ++i)
        if (values[i] < -1000.0 || values[i] > 1000.0) return -1;

    const int op = static_cast<int>(values[0]);
    const double ax = values[1], ay = values[2], bx = values[3], by = values[4];
    const double scalar = values[5];
    if (op == 1) {
        if (scalar < 0.0 || scalar > 2000.0) return -1;
    } else if (op == 6) {
        if (bx != 0.0 || by != 0.0 || scalar < -1000.0 || scalar > 1000.0) return -1;
    } else if (op == 9) {
        if (bx != 0.0 || by != 0.0 || scalar < -6.283185307179586 || scalar > 6.283185307179586) return -1;
    } else if (scalar != 0.0) return -1;
    if ((op == 2 || op == 3) && (bx != 0.0 || by != 0.0)) return -1;

    double result[2] = {0.0, 0.0};
    std::size_t result_length = 1;
    if (op == 0) result[0] = ax == bx && ay == by ? 1.0 : 0.0;
    else if (op == 1) result[0] = std::abs(ax - bx) < scalar && std::abs(ay - by) < scalar ? 1.0 : 0.0;
    else if (op == 2) result[0] = std::sqrt(ax * ax + ay * ay);
    else if (op == 3) {
        const double magnitude = std::sqrt(ax * ax + ay * ay);
        if (magnitude == 0.0) return -1;
        result_length = 2; result[0] = ax / magnitude; result[1] = ay / magnitude;
    } else if (op == 4) {
        result_length = 2; result[0] = ax + bx; result[1] = ay + by;
    } else if (op == 5) {
        result_length = 2; result[0] = ax - bx; result[1] = ay - by;
    } else if (op == 6) {
        result_length = 2; result[0] = ax * scalar; result[1] = ay * scalar;
    } else if (op == 7) {
        const double dx = bx - ax, dy = by - ay;
        result[0] = std::sqrt(dx * dx + dy * dy);
    } else if (op == 8) result[0] = ax * bx + ay * by;
    else if (op == 9) {
        const double cosine = std::cos(scalar), sine = std::sin(scalar);
        result_length = 2;
        result[0] = cosine * ax - sine * ay;
        result[1] = sine * ax + cosine * ay;
    } else result[0] = std::atan2(by, bx) - std::atan2(ay, ax);

    if (output == nullptr || capacity < result_length) return -2;
    for (std::size_t i = 0; i < result_length; ++i) output[i] = result[i];
    return static_cast<int64_t>(result_length);
}
