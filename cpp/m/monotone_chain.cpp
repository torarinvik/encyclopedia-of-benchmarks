#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_point_count = 64;
constexpr std::size_t max_parseable_input_length = 130;
constexpr std::int64_t max_coordinate = 1000000;

struct Point { std::int32_t x; std::int32_t y; };

bool point_less(Point a, Point b) {
    return a.x < b.x || (a.x == b.x && a.y < b.y);
}

std::int64_t cross(Point origin, Point first, Point second) {
    const auto dx1 = static_cast<std::int64_t>(first.x) - origin.x;
    const auto dy1 = static_cast<std::int64_t>(first.y) - origin.y;
    const auto dx2 = static_cast<std::int64_t>(second.x) - origin.x;
    const auto dy2 = static_cast<std::int64_t>(second.y) - origin.y;
    return dx1 * dy2 - dy1 * dx2;
}

void store_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
} // namespace

// Andrew's monotone-chain hull over a bounded integer point set.
extern "C" std::int64_t monotone_chain(const std::int64_t *values,
                                       std::size_t length,
                                       std::uint8_t *output,
                                       std::size_t capacity) {
    if (values == nullptr || length < 1 || length > max_parseable_input_length) return -1;
    const auto raw_count = values[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(max_point_count)) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    if (length != 1 + 2 * count) return -1;

    Point points[max_point_count]{};
    Point scratch[max_point_count]{};
    Point hull[2 * max_point_count]{};
    for (std::size_t index = 0; index < count; ++index) {
        const auto x = values[1 + 2 * index];
        const auto y = values[2 + 2 * index];
        if (x < -max_coordinate || x > max_coordinate ||
            y < -max_coordinate || y > max_coordinate) return -1;
        points[index] = {static_cast<std::int32_t>(x), static_cast<std::int32_t>(y)};
    }

    for (std::size_t width = 1; width < count; width *= 2) {
        for (std::size_t start = 0; start < count; start += 2 * width) {
            auto middle = start + width;
            if (middle > count) middle = count;
            auto end = middle + width;
            if (end > count) end = count;
            auto left = start;
            auto right = middle;
            auto destination = start;
            while (left < middle && right < end)
                scratch[destination++] = point_less(points[right], points[left]) ? points[right++] : points[left++];
            while (left < middle) scratch[destination++] = points[left++];
            while (right < end) scratch[destination++] = points[right++];
        }
        for (std::size_t index = 0; index < count; ++index) points[index] = scratch[index];
    }

    std::size_t unique_count = 0;
    for (std::size_t index = 0; index < count; ++index) {
        if (unique_count == 0 || points[index].x != points[unique_count - 1].x ||
            points[index].y != points[unique_count - 1].y)
            points[unique_count++] = points[index];
    }

    std::size_t hull_count = 0;
    if (unique_count == 1) {
        hull[hull_count++] = points[0];
    } else if (unique_count > 1) {
        for (std::size_t index = 0; index < unique_count; ++index) {
            while (hull_count >= 2 &&
                   cross(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0)
                --hull_count;
            hull[hull_count++] = points[index];
        }
        const auto lower_count = hull_count;
        for (std::size_t index = unique_count - 1; index > 0;) {
            --index;
            while (hull_count > lower_count &&
                   cross(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0)
                --hull_count;
            hull[hull_count++] = points[index];
        }
        --hull_count;
    }

    const auto byte_count = 8 * hull_count;
    if (output == nullptr || capacity < byte_count) return -2;
    for (std::size_t index = 0; index < hull_count; ++index) {
        store_i32_le(output, 8 * index, hull[index].x);
        store_i32_le(output, 8 * index + 4, hull[index].y);
    }
    return static_cast<std::int64_t>(byte_count);
}
