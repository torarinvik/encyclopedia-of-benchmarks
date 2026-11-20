/// Exact incremental 3D convex hull volume for general-position points.
const std = @import("std");
const point_capacity: usize = 6;
const face_capacity: usize = 64;
const edge_capacity: usize = 3 * face_capacity;

fn sideOfFace(points: [*]const i64, a: usize, b: usize, c: usize, point: usize) i64 {
    const abx = points[3 * b] - points[3 * a];
    const aby = points[3 * b + 1] - points[3 * a + 1];
    const abz = points[3 * b + 2] - points[3 * a + 2];
    const acx = points[3 * c] - points[3 * a];
    const acy = points[3 * c + 1] - points[3 * a + 1];
    const acz = points[3 * c + 2] - points[3 * a + 2];
    const apx = points[3 * point] - points[3 * a];
    const apy = points[3 * point + 1] - points[3 * a + 1];
    const apz = points[3 * point + 2] - points[3 * a + 2];
    return (aby * acz - abz * acy) * apx
        + (abz * acx - abx * acz) * apy
        + (abx * acy - aby * acx) * apz;
}

fn centerSide(points: [*]const i64, a: usize, b: usize, c: usize, center_sum: [3]i64) i64 {
    const abx = points[3 * b] - points[3 * a];
    const aby = points[3 * b + 1] - points[3 * a + 1];
    const abz = points[3 * b + 2] - points[3 * a + 2];
    const acx = points[3 * c] - points[3 * a];
    const acy = points[3 * c + 1] - points[3 * a + 1];
    const acz = points[3 * c + 2] - points[3 * a + 2];
    const dx = center_sum[0] - 4 * points[3 * a];
    const dy = center_sum[1] - 4 * points[3 * a + 1];
    const dz = center_sum[2] - 4 * points[3 * a + 2];
    return (aby * acz - abz * acy) * dx
        + (abz * acx - abx * acz) * dy
        + (abx * acy - aby * acx) * dz;
}

fn originDeterminant(points: [*]const i64, a: usize, b: usize, c: usize) i64 {
    const ax = points[3 * a]; const ay = points[3 * a + 1]; const az = points[3 * a + 2];
    const bx = points[3 * b]; const by = points[3 * b + 1]; const bz = points[3 * b + 2];
    const cx = points[3 * c]; const cy = points[3 * c + 1]; const cz = points[3 * c + 2];
    return ax * (by * cz - bz * cy) + ay * (bz * cx - bx * cz) + az * (bx * cy - by * cx);
}

export fn incremental_convex_hull_3d(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > 20) return -1;
    const input = input_opt.?;
    if (input[0] < 4 or input[0] > @as(i64, @intCast(point_capacity))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 3 * n) return -1;
    var points: [3 * point_capacity]i64 = @splat(0);
    for (0..3 * n) |i| {
        if (input[i + 1] < -10 or input[i + 1] > 10) return -1;
        points[i] = input[i + 1];
    }
    for (0..n) |i| for (i + 1..n) |j| {
        if (points[3 * i] == points[3 * j] and points[3 * i + 1] == points[3 * j + 1]
            and points[3 * i + 2] == points[3 * j + 2]) return -1;
    };
    for (0..n) |i| for (i + 1..n) |j| for (j + 1..n) |k| for (k + 1..n) |ell| {
        if (sideOfFace(&points, i, j, k, ell) == 0) return -1;
    };

    var center_sum: [3]i64 = @splat(0);
    for (0..4) |i| for (0..3) |axis| { center_sum[axis] += points[3 * i + axis]; };
    var face_a: [face_capacity]usize = @splat(0);
    var face_b: [face_capacity]usize = @splat(0);
    var face_c: [face_capacity]usize = @splat(0);
    face_a[0] = 0; face_a[1] = 0; face_a[2] = 0; face_a[3] = 1;
    face_b[0] = 1; face_b[1] = 3; face_b[2] = 2; face_b[3] = 3;
    face_c[0] = 2; face_c[1] = 1; face_c[2] = 3; face_c[3] = 2;
    var face_count: usize = 4;
    for (0..face_count) |face| {
        if (centerSide(&points, face_a[face], face_b[face], face_c[face], center_sum) > 0)
            std.mem.swap(usize, &face_b[face], &face_c[face]);
    }

    for (4..n) |point| {
        var visible: [face_capacity]bool = @splat(false);
        var visible_count: usize = 0;
        for (0..face_count) |face| {
            visible[face] = sideOfFace(&points, face_a[face], face_b[face], face_c[face], point) > 0;
            if (visible[face]) visible_count += 1;
        }
        if (visible_count == 0) continue;
        var edge_a: [edge_capacity]usize = @splat(0);
        var edge_b: [edge_capacity]usize = @splat(0);
        var edge_count: usize = 0;
        for (0..face_count) |face| if (visible[face]) {
            edge_a[edge_count] = face_a[face]; edge_b[edge_count] = face_b[face]; edge_count += 1;
            edge_a[edge_count] = face_b[face]; edge_b[edge_count] = face_c[face]; edge_count += 1;
            edge_a[edge_count] = face_c[face]; edge_b[edge_count] = face_a[face]; edge_count += 1;
        };
        var next_a: [face_capacity]usize = @splat(0);
        var next_b: [face_capacity]usize = @splat(0);
        var next_c: [face_capacity]usize = @splat(0);
        var next_count: usize = 0;
        for (0..face_count) |face| if (!visible[face]) {
            next_a[next_count] = face_a[face]; next_b[next_count] = face_b[face];
            next_c[next_count] = face_c[face]; next_count += 1;
        };
        for (0..edge_count) |edge| {
            var copies: usize = 0;
            for (0..edge_count) |other| {
                if ((edge_a[edge] == edge_a[other] and edge_b[edge] == edge_b[other])
                    or (edge_a[edge] == edge_b[other] and edge_b[edge] == edge_a[other])) copies += 1;
            }
            if (copies != 1) continue;
            if (next_count >= face_capacity) return -1;
            const a = edge_a[edge]; var b = edge_b[edge]; var c = point;
            if (centerSide(&points, a, b, c, center_sum) > 0) std.mem.swap(usize, &b, &c);
            next_a[next_count] = a; next_b[next_count] = b; next_c[next_count] = c; next_count += 1;
        }
        @memcpy(face_a[0..next_count], next_a[0..next_count]);
        @memcpy(face_b[0..next_count], next_b[0..next_count]);
        @memcpy(face_c[0..next_count], next_c[0..next_count]);
        face_count = next_count;
    }

    var volume_six: i64 = 0;
    for (0..face_count) |face| volume_six += originDeterminant(&points, face_a[face], face_b[face], face_c[face]);
    return volume_six;
}
