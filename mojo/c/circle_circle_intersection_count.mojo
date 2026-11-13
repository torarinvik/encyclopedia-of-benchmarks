from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_COORDINATE = 1000
alias MAX_RADIUS = 1000

fn classify(x1: Int64, y1: Int64, r1: Int64,
            x2: Int64, y2: Int64, r2: Int64) -> Int64:
    let dx = x2 - x1
    let dy = y2 - y1
    if dx == 0 and dy == 0:
        if r1 == r2:
            return 3
        return 0
    let a = -2 * dx
    let b = -2 * dy
    let c = dx * dx + dy * dy + r1 * r1 - r2 * r2
    let discriminant = r1 * r1 * (a * a + b * b) - c * c
    if discriminant < 0:
        return 0
    if discriminant == 0:
        return 1
    return 2

@export("circle_circle_intersection_count")
fn circle_circle_intersection_count(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 6:
        return -1
    let x1 = input[0]
    let y1 = input[1]
    let r1 = input[2]
    let x2 = input[3]
    let y2 = input[4]
    let r2 = input[5]
    if x1 < -MAX_COORDINATE or x1 > MAX_COORDINATE or
       y1 < -MAX_COORDINATE or y1 > MAX_COORDINATE or
       x2 < -MAX_COORDINATE or x2 > MAX_COORDINATE or
       y2 < -MAX_COORDINATE or y2 > MAX_COORDINATE or
       r1 < 1 or r1 > MAX_RADIUS or r2 < 1 or r2 > MAX_RADIUS:
        return -1
    return classify(x1, y1, r1, x2, y2, r2)
