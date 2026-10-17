#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_point_count = 64;
constexpr std::size_t max_parseable_input_values = 130;
constexpr std::size_t max_output_bytes = 513;

struct Point {
    std::int32_t x;
    std::int32_t y;
};

bool dominates(const Point& left, const Point& right) noexcept
{
    return (left.x < right.x && left.y <= right.y) ||
           (left.x <= right.x && left.y < right.y);
}

std::size_t produce_skyline(const Point* points, std::size_t count, Point* output) noexcept
{
    if (count == 1) {
        output[0] = points[0];
        return 1;
    }
    if (count == 2) {
        if (dominates(points[0], points[1])) {
            output[0] = points[0];
            return 1;
        }
        if (dominates(points[1], points[0])) {
            output[0] = points[1];
            return 1;
        }
        output[0] = points[0];
        output[1] = points[1];
        return 2;
    }

    const std::size_t middle = count / 2;
    Point left[max_point_count]{};
    Point right[max_point_count]{};
    std::size_t left_count = produce_skyline(points, middle, left);
    std::size_t right_count = produce_skyline(points + middle, count - middle, right);

    /* Match the source's adjacent same-x cleanup of the left frontier. */
    std::size_t index = 0;
    while (index + 1 < left_count) {
        if (left[index].x == left[index + 1].x && left[index].y > left[index + 1].y) {
            for (std::size_t move = index; move + 1 < left_count; ++move) {
                left[move] = left[move + 1];
            }
            --left_count;
            if (index > 0) --index;
        } else {
            ++index;
        }
    }

    std::int32_t minimum_y = left[0].y;
    for (index = 1; index < left_count; ++index) {
        if (minimum_y > left[index].y) {
            minimum_y = left[index].y;
            if (minimum_y == 1) break;
        }
    }

    index = 0;
    while (index < right_count) {
        if (right[index].y >= minimum_y) {
            for (std::size_t move = index; move + 1 < right_count; ++move) {
                right[move] = right[move + 1];
            }
            --right_count;
        } else {
            ++index;
        }
    }

    for (index = 0; index < left_count; ++index) output[index] = left[index];
    for (std::size_t right_index = 0; right_index < right_count; ++right_index) {
        output[left_count + right_index] = right[right_index];
    }
    return left_count + right_count;
}

void write_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) noexcept
{
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    output[offset] = static_cast<std::uint8_t>(bits);
    output[offset + 1] = static_cast<std::uint8_t>(bits >> 8);
    output[offset + 2] = static_cast<std::uint8_t>(bits >> 16);
    output[offset + 3] = static_cast<std::uint8_t>(bits >> 24);
}
} // namespace

extern "C" std::int64_t skyline_algorithm(const std::int64_t* input,
                                            std::size_t input_length,
                                            std::uint8_t* output,
                                            std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 3 ||
        input_length > max_parseable_input_values) return -1;

    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_point_count)) return -1;
    const std::size_t point_count = static_cast<std::size_t>(input[0]);
    if (input_length != 1 + 2 * point_count) return -1;

    Point points[max_point_count]{};
    for (std::size_t index = 0; index < point_count; ++index) {
        const std::int64_t x = input[1 + 2 * index];
        const std::int64_t y = input[2 + 2 * index];
        if (x < INT32_MIN || x > INT32_MAX || y < 1 || y > INT32_MAX) return -1;
        if (index > 0 && x <= input[1 + 2 * (index - 1)]) return -1;
        points[index].x = static_cast<std::int32_t>(x);
        points[index].y = static_cast<std::int32_t>(y);
    }

    Point skyline[max_point_count]{};
    const std::size_t skyline_count = produce_skyline(points, point_count, skyline);
    std::uint8_t staged[max_output_bytes]{};
    staged[0] = static_cast<std::uint8_t>(skyline_count);
    for (std::size_t index = 0; index < skyline_count; ++index) {
        const std::size_t offset = 1 + 8 * index;
        write_i32_le(staged, offset, skyline[index].x);
        write_i32_le(staged, offset + 4, skyline[index].y);
    }

    const std::size_t output_length = 1 + 8 * skyline_count;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_length);
}
