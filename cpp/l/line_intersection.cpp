#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
struct Point { std::int64_t x, y; };
bool same(Point a, Point b) noexcept { return a.x == b.x && a.y == b.y; }
std::int64_t cross(Point a, Point b, Point c) noexcept {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
bool on_segment(Point a, Point b, Point p) noexcept {
    return cross(a, b, p) == 0 && std::min(a.x, b.x) <= p.x && p.x <= std::max(a.x, b.x) &&
        std::min(a.y, b.y) <= p.y && p.y <= std::max(a.y, b.y);
}
void write_f64_le(std::uint8_t* output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
std::int64_t write_point(std::uint8_t* output, std::size_t capacity, double x, double y) noexcept {
    if (output == nullptr || capacity < 16) return -2;
    write_f64_le(output, 0, x);
    write_f64_le(output, 8, y);
    return 1;
}
}

extern "C" std::int64_t line_intersection(const std::int64_t* values, std::size_t length,
                                            std::uint8_t* output,
                                            std::size_t output_capacity) noexcept {
    if (length != 9 || values == nullptr || (values[8] != 0 && values[8] != 1)) return -1;
    for (std::size_t index = 0; index < 8; ++index)
        if (values[index] < -10000 || values[index] > 10000) return -1;
    const Point p1{values[0], values[1]}, p2{values[2], values[3]};
    const Point q1{values[4], values[5]}, q2{values[6], values[7]};
    const bool segments = values[8] == 1;
    const bool p_point = same(p1, p2), q_point = same(q1, q2);
    if (!segments && (p_point || q_point)) return -1;
    if (segments && p_point && q_point)
        return same(p1, q1) ? write_point(output, output_capacity, static_cast<double>(p1.x), static_cast<double>(p1.y)) : 0;
    if (segments && p_point)
        return on_segment(q1, q2, p1) ? write_point(output, output_capacity, static_cast<double>(p1.x), static_cast<double>(p1.y)) : 0;
    if (segments && q_point)
        return on_segment(p1, p2, q1) ? write_point(output, output_capacity, static_cast<double>(q1.x), static_cast<double>(q1.y)) : 0;

    const auto denominator = (p1.x - p2.x) * (q1.y - q2.y) - (p1.y - p2.y) * (q1.x - q2.x);
    if (denominator == 0) return 0;
    const auto determinant_p = p1.x * p2.y - p1.y * p2.x;
    const auto determinant_q = q1.x * q2.y - q1.y * q2.x;
    const auto numerator_x = determinant_p * (q1.x - q2.x) - (p1.x - p2.x) * determinant_q;
    const auto numerator_y = determinant_p * (q1.y - q2.y) - (p1.y - p2.y) * determinant_q;
    if (segments) {
        const auto positive_denominator = denominator < 0 ? -denominator : denominator;
        const auto positive_x = denominator < 0 ? -numerator_x : numerator_x;
        const auto positive_y = denominator < 0 ? -numerator_y : numerator_y;
        const auto min_x = std::max(std::min(p1.x, p2.x), std::min(q1.x, q2.x));
        const auto max_x = std::min(std::max(p1.x, p2.x), std::max(q1.x, q2.x));
        const auto min_y = std::max(std::min(p1.y, p2.y), std::min(q1.y, q2.y));
        const auto max_y = std::min(std::max(p1.y, p2.y), std::max(q1.y, q2.y));
        if (positive_x < min_x * positive_denominator || positive_x > max_x * positive_denominator ||
            positive_y < min_y * positive_denominator || positive_y > max_y * positive_denominator) return 0;
        return write_point(output, output_capacity, static_cast<double>(positive_x) / positive_denominator,
                           static_cast<double>(positive_y) / positive_denominator);
    }
    return write_point(output, output_capacity, static_cast<double>(numerator_x) / denominator,
                       static_cast<double>(numerator_y) / denominator);
}
