#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_points = 12;

struct Circle {
    double x;
    double y;
    double radius;
    bool valid;
};

bool contains_all(const Circle& circle, const std::int64_t* values, std::size_t count) noexcept {
    const double radius_squared = circle.radius * circle.radius;
    for (std::size_t index = 0; index < count; ++index) {
        const double dx = static_cast<double>(values[2 * index]) - circle.x;
        const double dy = static_cast<double>(values[2 * index + 1]) - circle.y;
        if (dx * dx + dy * dy > radius_squared + 1e-12) return false;
    }
    return true;
}

void consider(Circle candidate, const std::int64_t* values, std::size_t count,
              Circle& best) noexcept {
    if (contains_all(candidate, values, count) && (!best.valid || candidate.radius <= best.radius)) {
        candidate.valid = true;
        best = candidate;
    }
}

void write_f64_le(std::uint8_t* output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t smallest_circle(const std::int64_t* values, std::size_t length,
                                           std::uint8_t* output,
                                           std::size_t output_capacity) noexcept {
    if (length < 2 || length > 2 * max_points || length % 2 != 0 || values == nullptr) return -1;
    const std::size_t count = length / 2;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < -100 || values[index] > 100) return -1;

    Circle best{0.0, 0.0, 0.0, false};
    if (count == 1) {
        best = {static_cast<double>(values[0]), static_cast<double>(values[1]), 0.0, true};
    } else {
        for (std::size_t i = 0; i < count; ++i) {
            const double ax = static_cast<double>(values[2 * i]);
            const double ay = static_cast<double>(values[2 * i + 1]);
            for (std::size_t j = i + 1; j < count; ++j) {
                const double bx = static_cast<double>(values[2 * j]);
                const double by = static_cast<double>(values[2 * j + 1]);
                for (std::size_t k = j + 1; k < count; ++k) {
                    const double cx = static_cast<double>(values[2 * k]);
                    const double cy = static_cast<double>(values[2 * k + 1]);
                    const double denominator = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
                    if (denominator == 0.0) continue;
                    const double a_squared = ax * ax + ay * ay;
                    const double b_squared = bx * bx + by * by;
                    const double c_squared = cx * cx + cy * cy;
                    const double center_x = (a_squared * (by - cy) + b_squared * (cy - ay) +
                                             c_squared * (ay - by)) / denominator;
                    const double center_y = (a_squared * (cx - bx) + b_squared * (ax - cx) +
                                             c_squared * (bx - ax)) / denominator;
                    const double dx = center_x - ax, dy = center_y - ay;
                    consider({center_x, center_y, std::sqrt(dx * dx + dy * dy), false}, values, count, best);
                }
            }
        }
        for (std::size_t i = 0; i < count; ++i) {
            const double ax = static_cast<double>(values[2 * i]);
            const double ay = static_cast<double>(values[2 * i + 1]);
            for (std::size_t j = i + 1; j < count; ++j) {
                const double bx = static_cast<double>(values[2 * j]);
                const double by = static_cast<double>(values[2 * j + 1]);
                const double center_x = (ax + bx) / 2.0, center_y = (ay + by) / 2.0;
                const double dx = bx - ax, dy = by - ay;
                consider({center_x, center_y, std::sqrt(dx * dx + dy * dy) / 2.0, false}, values, count, best);
            }
        }
    }
    if (!best.valid) return -1;
    if (output == nullptr || output_capacity < 24) return -2;
    write_f64_le(output, 0, best.x);
    write_f64_le(output, 8, best.y);
    write_f64_le(output, 16, best.radius);
    return 1;
}
