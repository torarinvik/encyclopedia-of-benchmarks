#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t kMaxLines = 32;
constexpr std::size_t kMaxQueries = 32;
constexpr std::size_t kMaxLength = 99;
constexpr std::int64_t kInvalid = std::numeric_limits<std::int64_t>::min();

struct Line { std::int64_t slope; std::int64_t intercept; };

std::int64_t value(const Line &line, std::int64_t x)
{
    return line.slope * x + line.intercept;
}

bool redundant(const Line &a, const Line &b, const Line &c)
{
    return (b.intercept - a.intercept) * (b.slope - c.slope)
        >= (c.intercept - b.intercept) * (a.slope - b.slope);
}
}

extern "C" std::int64_t monotone_convex_hull_trick(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > kMaxLength) return kInvalid;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(kMaxLines)
        || values[1] < 0 || values[1] > static_cast<std::int64_t>(kMaxQueries)) return kInvalid;
    const auto line_count = static_cast<std::size_t>(values[0]);
    const auto query_count = static_cast<std::size_t>(values[1]);
    if (length != 2 + 2 * line_count + query_count) return kInvalid;

    std::array<Line, kMaxLines> hull{};
    std::size_t hull_count = 0;
    std::int64_t previous_slope = std::numeric_limits<std::int64_t>::max();
    std::size_t cursor = 2;
    for (std::size_t i = 0; i < line_count; ++i) {
        const Line line{values[cursor], values[cursor + 1]};
        cursor += 2;
        if (line.slope < -1000 || line.slope > 1000 || line.intercept < -10000
            || line.intercept > 10000 || line.slope >= previous_slope) return kInvalid;
        previous_slope = line.slope;
        while (hull_count >= 2 && redundant(hull[hull_count - 2], hull[hull_count - 1], line)) --hull_count;
        hull[hull_count++] = line;
    }

    std::size_t front = 0;
    std::int64_t checksum = 0;
    std::int64_t previous_x = std::numeric_limits<std::int64_t>::min();
    for (std::size_t i = 0; i < query_count; ++i) {
        const std::int64_t x = values[cursor + i];
        if (x < -1000 || x > 1000 || (i != 0 && x < previous_x)) return kInvalid;
        previous_x = x;
        while (front + 1 < hull_count && value(hull[front + 1], x) <= value(hull[front], x)) ++front;
        checksum += static_cast<std::int64_t>(i + 1) * value(hull[front], x);
    }
    return checksum;
}
