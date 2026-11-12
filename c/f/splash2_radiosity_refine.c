#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_DEPTH 5u
#define MAX_OUTPUT 3u

static double factor(double tx, double ty, double source_area,
                     double sx, double sy, double gap)
{
    const double distance_squared = (sx - tx) * (sx - tx)
        + (sy - ty) * (sy - ty) + gap * gap;
    return source_area * gap * gap / (distance_squared * distance_squared);
}

static void visit(double tx, double ty, double target_side,
                  double sx, double sy, double source_side, double gap,
                  double bound, size_t max_depth, size_t depth, double weight,
                  double *transfer, size_t *leaves, size_t *deepest)
{
    const double coarse = factor(tx, ty, source_side * source_side, sx, sy, gap);
    const int split_source = source_side >= target_side;
    const double parent_side = split_source ? source_side : target_side;
    const double child_side = parent_side * 0.5;
    const double offset = parent_side * 0.25;
    double fine = 0.0;
    for (size_t quadrant = 0; quadrant < 4; ++quadrant) {
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
    double error = fine - coarse;
    if (error < 0.0) error = -error;
    if (depth >= max_depth || error <= bound) {
        *transfer += weight * coarse;
        ++*leaves;
        if (depth > *deepest) *deepest = depth;
        return;
    }
    for (size_t quadrant = 0; quadrant < 4; ++quadrant) {
        const double dx = (quadrant & 1u) ? offset : -offset;
        const double dy = (quadrant & 2u) ? offset : -offset;
        if (split_source) {
            visit(tx, ty, target_side, sx + dx, sy + dy, child_side, gap,
                  bound, max_depth, depth + 1, weight, transfer, leaves, deepest);
        } else {
            visit(tx + dx, ty + dy, child_side, sx, sy, source_side, gap,
                  bound, max_depth, depth + 1, weight * 0.25,
                  transfer, leaves, deepest);
        }
    }
}

int64_t splash2_radiosity_refine(const double *input, size_t input_length,
                                 double *output, size_t output_capacity)
{
    if (input == NULL || input_length != 11u) return -1;
    for (size_t i = 0; i < input_length; ++i) {
        if (!isfinite(input[i])) return -1;
    }
    const double tx = input[0], ty = input[1], target_side = input[2];
    const double sx = input[3], sy = input[4], source_side = input[5];
    const double gap = input[6], brightness = input[7];
    const double reflectance = input[8], bound = input[9], depth_value = input[10];
    if (tx < -8.0 || tx > 8.0 || ty < -8.0 || ty > 8.0
        || sx < -8.0 || sx > 8.0 || sy < -8.0 || sy > 8.0
        || (target_side != 1.0 && target_side != 2.0 && target_side != 4.0)
        || (source_side != 1.0 && source_side != 2.0 && source_side != 4.0)
        || gap < 1.0 || gap > 8.0 || target_side > gap || source_side > gap
        || brightness < 0.0 || brightness > 4.0
        || reflectance < 0.0 || reflectance > 1.0
        || bound < 0.0 || bound > 1.0
        || depth_value < 0.0 || depth_value > (double)MAX_DEPTH
        || depth_value != (double)(size_t)depth_value) return -1;
    if (output == NULL || output_capacity < MAX_OUTPUT) return -2;

    double transfer = 0.0;
    size_t leaves = 0, deepest = 0;
    visit(tx, ty, target_side, sx, sy, source_side, gap, bound,
          (size_t)depth_value, 0, 1.0, &transfer, &leaves, &deepest);
    output[0] = reflectance * brightness * transfer;
    output[1] = (double)leaves;
    output[2] = (double)deepest;
    return (int64_t)MAX_OUTPUT;
}
