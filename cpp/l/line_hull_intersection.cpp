#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 16;
constexpr std::size_t kMaxParseableLength = 38;
struct Point { std::int64_t x, y; };
struct Vector { std::int64_t x, y; };
struct Hit { std::int64_t edge, numerator, denominator; };

int polar_half(Vector value) noexcept {
    return value.y > 0 || (value.y == 0 && value.x >= 0) ? 0 : 1;
}
bool angle_before(Vector left, Vector right) noexcept {
    const int lh = polar_half(left), rh = polar_half(right);
    if (lh != rh) return lh < rh;
    return left.x * right.y - left.y * right.x > 0;
}
std::size_t rotation_minimum(const std::array<Vector, kMaxVertices>& edges,
                             std::size_t count) noexcept {
    std::size_t low = 0, high = count - 1;
    while (low < high) {
        const auto middle = (low + high) / 2;
        if (angle_before(edges[middle], edges[high])) high = middle;
        else low = middle + 1;
    }
    return low;
}
std::size_t support_edge(const std::array<Vector, kMaxVertices>& edges,
                         std::size_t count, Vector target) noexcept {
    const auto pivot = rotation_minimum(edges, count);
    std::size_t low = 0, high = count;
    while (low < high) {
        const auto middle = (low + high) / 2;
        if (angle_before(edges[(pivot + middle) % count], target)) low = middle + 1;
        else high = middle;
    }
    return (pivot + low) % count;
}
std::int64_t line_value(Point point, Point origin, Vector direction) noexcept {
    return direction.x * (point.y - origin.y) - direction.y * (point.x - origin.x);
}
std::int64_t line_parameter(Point point, Point origin, Vector direction) noexcept {
    return (point.x - origin.x) * direction.x + (point.y - origin.y) * direction.y;
}
Hit crossing(const std::array<Point, kMaxVertices>& points, std::size_t count,
             Point origin, Vector direction, std::size_t start, std::size_t end,
             bool increasing) noexcept {
    const auto span = (end + count - start) % count;
    std::size_t low = 0, high = span;
    while (high - low > 1) {
        const auto middle = (low + high) / 2;
        const auto value = line_value(points[(start + middle) % count], origin, direction);
        if (increasing ? value < 0 : value > 0) low = middle;
        else high = middle;
    }
    auto index = (start + low) % count;
    if (line_value(points[(start + high) % count], origin, direction) == 0)
        index = (start + high) % count;
    const auto value = line_value(points[index], origin, direction);
    if (value == 0) return {static_cast<std::int64_t>(index), line_parameter(points[index], origin, direction), 1};
    const auto next = (index + 1) % count;
    const auto next_value = line_value(points[next], origin, direction);
    auto denominator = value - next_value;
    const auto edge_dot = (points[next].x - points[index].x) * direction.x +
                          (points[next].y - points[index].y) * direction.y;
    auto numerator = line_parameter(points[index], origin, direction) * denominator + value * edge_dot;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    return {static_cast<std::int64_t>(index), numerator, denominator};
}
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t line_hull_intersection(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > kMaxParseableLength) return -1;
    const auto count_value = input[0];
    if (count_value < 3 || count_value > static_cast<std::int64_t>(kMaxVertices)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 5 + 2 * count) return -1;
    const Point origin{input[1], input[2]}, line_end{input[3], input[4]};
    if (origin.x < -50 || origin.x > 50 || origin.y < -50 || origin.y > 50 ||
        line_end.x < -50 || line_end.x > 50 || line_end.y < -50 || line_end.y > 50) return -1;
    const Vector direction{line_end.x - origin.x, line_end.y - origin.y};
    if (direction.x == 0 && direction.y == 0) return -1;

    std::array<Point, kMaxVertices> points{};
    std::array<Vector, kMaxVertices> edges{};
    for (std::size_t i = 0; i < count; ++i) {
        points[i] = {input[5 + 2 * i], input[6 + 2 * i]};
        if (points[i].x < -50 || points[i].x > 50 || points[i].y < -50 || points[i].y > 50) return -1;
        for (std::size_t j = 0; j < i; ++j)
            if (points[j].x == points[i].x && points[j].y == points[i].y) return -1;
    }
    std::int64_t area2 = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto next = (i + 1) % count;
        edges[i] = {points[next].x - points[i].x, points[next].y - points[i].y};
        area2 += points[i].x * points[next].y - points[next].x * points[i].y;
    }
    if (area2 <= 0) return -1;
    for (std::size_t i = 0; i < count; ++i) {
        const auto next = (i + 1) % count;
        for (std::size_t j = 0; j < count; ++j) {
            if (j == i || j == next) continue;
            const auto side = edges[i].x * (points[j].y - points[i].y) -
                              edges[i].y * (points[j].x - points[i].x);
            if (side <= 0) return -1;
        }
    }

    const auto maximum = support_edge(edges, count, {-direction.x, -direction.y});
    const auto minimum = support_edge(edges, count, direction);
    const auto max_value = line_value(points[maximum], origin, direction);
    const auto min_value = line_value(points[minimum], origin, direction);
    std::int64_t first = -1, second = -1;
    if (min_value > 0 || max_value < 0) {
        first = second = -1;
    } else if (min_value == 0 || max_value == 0) {
        const auto touch = min_value == 0 ? minimum : maximum;
        const auto next = (touch + 1) % count, previous = (touch + count - 1) % count;
        if (line_value(points[touch], origin, direction) == 0 &&
            line_value(points[next], origin, direction) == 0)
            first = second = static_cast<std::int64_t>(touch);
        else if (line_value(points[previous], origin, direction) == 0 &&
                 line_value(points[touch], origin, direction) == 0)
            first = second = static_cast<std::int64_t>(previous);
        else { first = static_cast<std::int64_t>(touch); second = -1; }
    } else {
        const auto a = crossing(points, count, origin, direction, maximum, minimum, false);
        const auto b = crossing(points, count, origin, direction, minimum, maximum, true);
        if (a.numerator * b.denominator <= b.numerator * a.denominator) {
            first = a.edge; second = b.edge;
        } else { first = b.edge; second = a.edge; }
    }
    if (output == nullptr || capacity < 16) return -2;
    store_i64_le(output, 0, first);
    store_i64_le(output, 8, second);
    return 16;
}
