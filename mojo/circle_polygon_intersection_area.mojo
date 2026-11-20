from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import atan2, sqrt

const INVALID_RESULT: Float64 = -1.0e300
const MAX_INPUT: Int = 37
const MAX_COORDINATE: Int64 = 32

@export("circle_polygon_intersection_area")
fn circle_polygon_intersection_area(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 10 or length > c_size_t(MAX_INPUT):
        return INVALID_RESULT
    let n_value = values[0]
    let cx = values[1]
    let cy = values[2]
    let radius_value = values[3]
    if n_value < 3 or n_value > 16:
        return INVALID_RESULT
    if length != c_size_t(4 + 2 * n_value):
        return INVALID_RESULT
    if cx < -MAX_COORDINATE or cx > MAX_COORDINATE or cy < -MAX_COORDINATE or cy > MAX_COORDINATE:
        return INVALID_RESULT
    if radius_value < 1 or radius_value > MAX_COORDINATE:
        return INVALID_RESULT
    let n = Int(n_value)
    for i in range(n):
        let x = values[4 + 2 * i]
        let y = values[5 + 2 * i]
        if x < -MAX_COORDINATE or x > MAX_COORDINATE or y < -MAX_COORDINATE or y > MAX_COORDINATE:
            return INVALID_RESULT
    for i in range(n):
        let next = (i + 1) % n
        let x = values[4 + 2 * i]
        let y = values[5 + 2 * i]
        let next_x = values[4 + 2 * next]
        let next_y = values[5 + 2 * next]
        let dx = next_x - x
        let dy = next_y - y
        for j in range(n):
            if j == i or j == next:
                continue
            let other_x = values[4 + 2 * j]
            let other_y = values[5 + 2 * j]
            if dx * (other_y - y) - dy * (other_x - x) <= 0:
                return INVALID_RESULT
        if dx * (cy - y) - dy * (cx - x) <= 0:
            return INVALID_RESULT

    let radius = Float64(radius_value)
    let radius_squared = radius * radius
    var doubled_area: Float64 = 0.0
    for i in range(n):
        let next = (i + 1) % n
        let px = Float64(values[4 + 2 * i] - cx)
        let py = Float64(values[5 + 2 * i] - cy)
        let qx = Float64(values[4 + 2 * next] - cx)
        let qy = Float64(values[5 + 2 * next] - cy)
        let dx = qx - px
        let dy = qy - py
        let edge_squared = dx * dx + dy * dy
        let projection = px * dx + py * dy
        let constant = px * px + py * py - radius_squared
        let discriminant = projection * projection - edge_squared * constant
        let full_angle = atan2(px * qy - py * qx, px * qx + py * qy)
        if discriminant <= 0.0:
            doubled_area += radius_squared * full_angle
            continue
        let root = sqrt(discriminant)
        let first = (-projection - root) / edge_squared
        let second = (-projection + root) / edge_squared
        if second < 0.0 or first > 1.0:
            doubled_area += radius_squared * full_angle
            continue
        let start = first if first > 0.0 else 0.0
        let stop = second if second < 1.0 else 1.0
        let ux = px + start * dx
        let uy = py + start * dy
        let vx = px + stop * dx
        let vy = py + stop * dy
        let first_angle = atan2(px * uy - py * ux, px * ux + py * uy)
        let last_angle = atan2(vx * qy - vy * qx, vx * qx + vy * qy)
        doubled_area += radius_squared * (first_angle + last_angle) + ux * vy - uy * vx
    return 0.5 * doubled_area
