const std = @import("std");

const MAX_DEPTH: usize = 5;

fn factor(tx: f64, ty: f64, source_area: f64, sx: f64, sy: f64, gap: f64) f64 {
    const distance_squared = (sx - tx) * (sx - tx) + (sy - ty) * (sy - ty) + gap * gap;
    return source_area * gap * gap / (distance_squared * distance_squared);
}

fn visit(tx: f64, ty: f64, target_side: f64, sx: f64, sy: f64, source_side: f64,
    gap: f64, bound: f64, allowed_depth: usize, depth: usize, weight: f64,
    transfer: *f64, leaves: *usize, deepest: *usize) void {
    const coarse = factor(tx, ty, source_side * source_side, sx, sy, gap);
    const split_source = source_side >= target_side;
    const parent_side = if (split_source) source_side else target_side;
    const child_side = parent_side * 0.5;
    const offset = parent_side * 0.25;
    var fine: f64 = 0;
    for (0..4) |quadrant| {
        const dx = if ((quadrant & 1) != 0) offset else -offset;
        const dy = if ((quadrant & 2) != 0) offset else -offset;
        if (split_source) {
            fine += factor(tx, ty, child_side * child_side, sx + dx, sy + dy, gap);
        } else {
            fine += 0.25 * factor(tx + dx, ty + dy, source_side * source_side, sx, sy, gap);
        }
    }
    if (depth >= allowed_depth or @abs(fine - coarse) <= bound) {
        transfer.* += weight * coarse;
        leaves.* += 1;
        deepest.* = @max(deepest.*, depth);
        return;
    }
    for (0..4) |quadrant| {
        const dx = if ((quadrant & 1) != 0) offset else -offset;
        const dy = if ((quadrant & 2) != 0) offset else -offset;
        if (split_source) {
            visit(tx, ty, target_side, sx + dx, sy + dy, child_side, gap,
                bound, allowed_depth, depth + 1, weight, transfer, leaves, deepest);
        } else {
            visit(tx + dx, ty + dy, child_side, sx, sy, source_side, gap,
                bound, allowed_depth, depth + 1, weight * 0.25, transfer, leaves, deepest);
        }
    }
}

export fn splash2_radiosity_refine(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length != 11) return -1;
    for (0..input_length) |i| if (!std.math.isFinite(values[i])) return -1;
    const tx=values[0]; const ty=values[1]; const ts=values[2];
    const sx=values[3]; const sy=values[4]; const ss=values[5];
    const gap=values[6]; const brightness=values[7]; const reflectance=values[8];
    const bound=values[9]; const depth_value=values[10];
    if (tx < -8 or tx > 8 or ty < -8 or ty > 8 or sx < -8 or sx > 8 or sy < -8 or sy > 8
        or !(ts == 1 or ts == 2 or ts == 4) or !(ss == 1 or ss == 2 or ss == 4)
        or gap < 1 or gap > 8 or ts > gap or ss > gap
        or brightness < 0 or brightness > 4 or reflectance < 0 or reflectance > 1
        or bound < 0 or bound > 1 or depth_value < 0 or depth_value > @as(f64, @floatFromInt(MAX_DEPTH))
        or @floor(depth_value) != depth_value) return -1;
    const out = output orelse return -2;
    if (output_capacity < 3) return -2;
    var transfer: f64 = 0;
    var leaves: usize = 0;
    var deepest: usize = 0;
    visit(tx, ty, ts, sx, sy, ss, gap, bound, @intFromFloat(depth_value), 0, 1,
        &transfer, &leaves, &deepest);
    out[0] = reflectance * brightness * transfer;
    out[1] = @floatFromInt(leaves);
    out[2] = @floatFromInt(deepest);
    return 3;
}
