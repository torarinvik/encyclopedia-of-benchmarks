#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 8;
constexpr std::size_t max_cells = 64;
constexpr std::size_t max_input_length = 79;
struct AxisSolution { std::int64_t first, second, translation; };

bool solve_axis(const std::int64_t x[3], const std::int64_t y[3], const std::int64_t target[3],
                AxisSolution& solution) {
    const std::int64_t determinant = x[0] * (y[1] - y[2]) + x[1] * (y[2] - y[0]) + x[2] * (y[0] - y[1]);
    if (determinant == 0) return false;
    const std::int64_t first = target[0] * (y[1] - y[2]) + target[1] * (y[2] - y[0]) + target[2] * (y[0] - y[1]);
    const std::int64_t second = x[0] * (target[1] - target[2]) + x[1] * (target[2] - target[0]) + x[2] * (target[0] - target[1]);
    const std::int64_t translation = x[0] * (y[1] * target[2] - y[2] * target[1])
        + x[1] * (y[2] * target[0] - y[0] * target[2]) + x[2] * (y[0] * target[1] - y[1] * target[0]);
    if (first % determinant != 0 || second % determinant != 0 || translation % determinant != 0) return false;
    solution = {first / determinant, second / determinant, translation / determinant};
    return true;
}
}

extern "C" std::int64_t affine_image_rotation(const std::int32_t* input, std::size_t length,
                                               std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t rows_value = input[0], cols_value = input[1];
    if (rows_value < 1 || rows_value > std::int64_t(max_dimension) || cols_value < 1 || cols_value > std::int64_t(max_dimension)) return -1;
    const std::size_t rows = std::size_t(rows_value), cols = std::size_t(cols_value), cells = rows * cols;
    if (length != 14 + cells) return -1;
    std::uint8_t pixels[max_cells]{};
    for (std::size_t i = 0; i < cells; ++i) {
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
        pixels[i] = std::uint8_t(input[2 + i]);
    }
    const std::size_t point_offset = 2 + cells;
    std::int64_t sx[3], sy[3], dx[3], dy[3];
    for (std::size_t i = 0; i < 3; ++i) {
        sx[i] = input[point_offset + 2 * i]; sy[i] = input[point_offset + 2 * i + 1];
        dx[i] = input[point_offset + 6 + 2 * i]; dy[i] = input[point_offset + 7 + 2 * i];
        if (sx[i] < -16 || sx[i] > 16 || sy[i] < -16 || sy[i] > 16 || dx[i] < -16 || dx[i] > 16 || dy[i] < -16 || dy[i] > 16) return -1;
    }
    AxisSolution x_axis{}, y_axis{};
    if (!solve_axis(sx, sy, dx, x_axis) || !solve_axis(sx, sy, dy, y_axis)) return -1;
    const auto a=x_axis.first, b=x_axis.second, tx=x_axis.translation;
    const auto c=y_axis.first, d=y_axis.second, ty=y_axis.translation;
    if (a < -2 || a > 2 || b < -2 || b > 2 || c < -2 || c > 2 || d < -2 || d > 2 || tx < -16 || tx > 16 || ty < -16 || ty > 16) return -1;
    const std::int64_t determinant = a * d - b * c;
    if (determinant != -1 && determinant != 1) return -1;
    for (std::size_t i = 0; i < 3; ++i)
        if (dx[i] != a*sx[i]+b*sy[i]+tx || dy[i] != c*sx[i]+d*sy[i]+ty) return -1;
    if (output == nullptr || capacity < cells) return -2;
    std::size_t written = 0;
    for (std::int64_t y = 0; y < std::int64_t(cols); ++y) for (std::int64_t x = 0; x < std::int64_t(rows); ++x) {
        const auto px=x-tx, py=y-ty;
        const auto source_x=(d*px-b*py)/determinant, source_y=(-c*px+a*py)/determinant;
        output[written++]=(source_x>=0&&source_x<std::int64_t(cols)&&source_y>=0&&source_y<std::int64_t(rows))
            ? pixels[std::size_t(source_y)*cols+std::size_t(source_x)] : 0;
    }
    return std::int64_t(cells);
}
