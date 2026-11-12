module splash2_radiosity_refine;

const usz MAX_DEPTH = 5;

fn double factor(double tx, double ty, double source_area,
                double sx, double sy, double gap) {
    double distance_squared = (sx - tx) * (sx - tx) + (sy - ty) * (sy - ty) + gap * gap;
    return source_area * gap * gap / (distance_squared * distance_squared);
}

fn void visit(double tx, double ty, double target_side, double sx, double sy,
              double source_side, double gap, double bound, usz allowed_depth,
              usz depth, double weight, double* transfer, usz* leaves, usz* deepest) {
    double coarse = factor(tx, ty, source_side * source_side, sx, sy, gap);
    bool split_source = source_side >= target_side;
    double parent_side = split_source ? source_side : target_side;
    double child_side = parent_side * 0.5;
    double offset = parent_side * 0.25;
    double fine = 0.0;
    for (usz quadrant = 0; quadrant < 4; quadrant++) {
        double dx = (quadrant & 1) != 0 ? offset : -offset;
        double dy = (quadrant & 2) != 0 ? offset : -offset;
        if (split_source) {
            fine += factor(tx, ty, child_side * child_side, sx + dx, sy + dy, gap);
        } else {
            fine += 0.25 * factor(tx + dx, ty + dy, source_side * source_side, sx, sy, gap);
        }
    }
    double error = fine - coarse;
    if (error < 0.0) error = -error;
    if (depth >= allowed_depth || error <= bound) {
        *transfer += weight * coarse;
        *leaves += 1;
        if (depth > *deepest) *deepest = depth;
        return;
    }
    for (usz quadrant = 0; quadrant < 4; quadrant++) {
        double dx = (quadrant & 1) != 0 ? offset : -offset;
        double dy = (quadrant & 2) != 0 ? offset : -offset;
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

fn long splash2_radiosity_refine(double* input, usz input_length, double* output,
                                usz output_capacity) @export("splash2_radiosity_refine") {
    if (input == null || input_length != 11) return -1L;
    for (usz i = 0; i < input_length; i++) {
        double value = input[i];
        if (!(value >= -1.0e300 && value <= 1.0e300)) return -1L;
    }
    double tx=input[0], ty=input[1], ts=input[2], sx=input[3], sy=input[4], ss=input[5];
    double gap=input[6], brightness=input[7], reflectance=input[8], bound=input[9], depth_value=input[10];
    if (tx < -8 || tx > 8 || ty < -8 || ty > 8 || sx < -8 || sx > 8 || sy < -8 || sy > 8
        || (ts != 1 && ts != 2 && ts != 4) || (ss != 1 && ss != 2 && ss != 4)
        || gap < 1 || gap > 8 || ts > gap || ss > gap || brightness < 0 || brightness > 4
        || reflectance < 0 || reflectance > 1 || bound < 0 || bound > 1
        || depth_value < 0 || depth_value > (double)MAX_DEPTH || (double)(usz)depth_value != depth_value) return -1L;
    if (output == null || output_capacity < 3) return -2L;
    double transfer = 0.0;
    usz leaves = 0, deepest = 0;
    visit(tx, ty, ts, sx, sy, ss, gap, bound, (usz)depth_value, 0, 1.0,
          &transfer, &leaves, &deepest);
    output[0] = reflectance * brightness * transfer;
    output[1] = (double)leaves;
    output[2] = (double)deepest;
    return 3L;
}
