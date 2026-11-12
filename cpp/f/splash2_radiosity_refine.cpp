#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_depth = 5;

double factor(double tx, double ty, double source_area,
              double sx, double sy, double gap) noexcept
{
    const double distance_squared = (sx - tx) * (sx - tx)
        + (sy - ty) * (sy - ty) + gap * gap;
    return source_area * gap * gap / (distance_squared * distance_squared);
}

void visit(double tx, double ty, double target_side,
           double sx, double sy, double source_side, double gap,
           double bound, std::size_t allowed_depth, std::size_t depth, double weight,
           double& transfer, std::size_t& leaves, std::size_t& deepest) noexcept
{
    const double coarse = factor(tx, ty, source_side * source_side, sx, sy, gap);
    const bool split_source = source_side >= target_side;
    const double parent_side = split_source ? source_side : target_side;
    const double child_side = parent_side * 0.5;
    const double offset = parent_side * 0.25;
    double fine = 0.0;
    for (std::size_t quadrant = 0; quadrant < 4; ++quadrant) {
        const double dx = (quadrant & 1u) ? offset : -offset;
        const double dy = (quadrant & 2u) ? offset : -offset;
        if (split_source) {
            fine += factor(tx, ty, child_side * child_side,
                           sx + dx, sy + dy, gap);
        } else {
            fine += 0.25 * factor(tx + dx, ty + dy, source_side * source_side,
                                  sx, sy, gap);
        }
    }
    const double error = std::abs(fine - coarse);
    if (depth >= allowed_depth || error <= bound) {
        transfer += weight * coarse;
        ++leaves;
        if (depth > deepest) deepest = depth;
        return;
    }
    for (std::size_t quadrant = 0; quadrant < 4; ++quadrant) {
        const double dx = (quadrant & 1u) ? offset : -offset;
        const double dy = (quadrant & 2u) ? offset : -offset;
        if (split_source) {
            visit(tx, ty, target_side, sx + dx, sy + dy, child_side, gap,
                  bound, allowed_depth, depth + 1, weight, transfer, leaves, deepest);
        } else {
            visit(tx + dx, ty + dy, child_side, sx, sy, source_side, gap,
                  bound, allowed_depth, depth + 1, weight * 0.25,
                  transfer, leaves, deepest);
        }
    }
}
}

extern "C" std::int64_t splash2_radiosity_refine(const double *input,
    std::size_t input_length, double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length != 11) return -1;
    for (std::size_t i = 0; i < input_length; ++i) if (!std::isfinite(input[i])) return -1;
    const double tx=input[0], ty=input[1], ts=input[2], sx=input[3], sy=input[4], ss=input[5];
    const double gap=input[6], brightness=input[7], reflectance=input[8], bound=input[9], depth_value=input[10];
    if (tx < -8 || tx > 8 || ty < -8 || ty > 8 || sx < -8 || sx > 8 || sy < -8 || sy > 8
        || (ts != 1 && ts != 2 && ts != 4) || (ss != 1 && ss != 2 && ss != 4)
        || gap < 1 || gap > 8 || ts > gap || ss > gap
        || brightness < 0 || brightness > 4 || reflectance < 0 || reflectance > 1
        || bound < 0 || bound > 1 || depth_value < 0 || depth_value > max_depth
        || std::floor(depth_value) != depth_value) return -1;
    if (output == nullptr || output_capacity < 3) return -2;
    double transfer = 0;
    std::size_t leaves = 0, deepest = 0;
    visit(tx, ty, ts, sx, sy, ss, gap, bound, static_cast<std::size_t>(depth_value),
          0, 1, transfer, leaves, deepest);
    output[0] = reflectance * brightness * transfer;
    output[1] = static_cast<double>(leaves);
    output[2] = static_cast<double>(deepest);
    return 3;
}
