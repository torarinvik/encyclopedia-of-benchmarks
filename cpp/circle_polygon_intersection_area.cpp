#include <array>
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 16;
constexpr std::size_t max_input = 37;
constexpr std::int64_t max_coordinate = 32;
constexpr double invalid_result = -1.0e300;
}

extern "C" double circle_polygon_intersection_area(const std::int64_t *values,
                                                     std::size_t length) noexcept {
    if (values == nullptr || length < 10 || length > max_input) return invalid_result;
    const auto n_value = values[0], cx = values[1], cy = values[2], radius_value = values[3];
    if (n_value < 3 || n_value > static_cast<std::int64_t>(max_vertices)) return invalid_result;
    if (length != static_cast<std::size_t>(4 + 2 * n_value) ||
        cx < -max_coordinate || cx > max_coordinate || cy < -max_coordinate || cy > max_coordinate ||
        radius_value < 1 || radius_value > max_coordinate) return invalid_result;

    const auto n = static_cast<std::size_t>(n_value);
    std::array<std::int64_t, max_vertices> x{}, y{};
    for (std::size_t i = 0; i < n; ++i) {
        x[i] = values[4 + 2 * i];
        y[i] = values[5 + 2 * i];
        if (x[i] < -max_coordinate || x[i] > max_coordinate ||
            y[i] < -max_coordinate || y[i] > max_coordinate) return invalid_result;
    }
    for (std::size_t i = 0; i < n; ++i) {
        const auto next = (i + 1) % n;
        const auto dx = x[next] - x[i], dy = y[next] - y[i];
        for (std::size_t j = 0; j < n; ++j) {
            if (j == i || j == next) continue;
            if (dx * (y[j] - y[i]) - dy * (x[j] - x[i]) <= 0) return invalid_result;
        }
        if (dx * (cy - y[i]) - dy * (cx - x[i]) <= 0) return invalid_result;
    }

    const double radius = static_cast<double>(radius_value);
    const double radius_squared = radius * radius;
    double doubled_area = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto next = (i + 1) % n;
        const double px = static_cast<double>(x[i] - cx), py = static_cast<double>(y[i] - cy);
        const double qx = static_cast<double>(x[next] - cx), qy = static_cast<double>(y[next] - cy);
        const double dx = qx - px, dy = qy - py;
        const double edge_squared = dx * dx + dy * dy;
        const double projection = px * dx + py * dy;
        const double constant = px * px + py * py - radius_squared;
        const double discriminant = projection * projection - edge_squared * constant;
        const double full_angle = std::atan2(px * qy - py * qx, px * qx + py * qy);
        if (discriminant <= 0.0) {
            doubled_area += radius_squared * full_angle;
            continue;
        }
        const double root = std::sqrt(discriminant);
        const double first = (-projection - root) / edge_squared;
        const double second = (-projection + root) / edge_squared;
        if (second < 0.0 || first > 1.0) {
            doubled_area += radius_squared * full_angle;
            continue;
        }
        const double start = std::max(0.0, first), stop = std::min(1.0, second);
        const double ux = px + start * dx, uy = py + start * dy;
        const double vx = px + stop * dx, vy = py + stop * dy;
        const double first_angle = std::atan2(px * uy - py * ux, px * ux + py * uy);
        const double last_angle = std::atan2(vx * qy - vy * qx, vx * qx + vy * qy);
        doubled_area += radius_squared * (first_angle + last_angle) + ux * vy - uy * vx;
    }
    return 0.5 * doubled_area;
}
