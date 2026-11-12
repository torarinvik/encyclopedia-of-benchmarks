from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_COORDINATE = 100000
alias MAX_RADIUS = 100000

fn count_tangents(x1: Int64, y1: Int64, r1: Int64, x2: Int64, y2: Int64, r2: Int64) -> Int64:
    let dx = x2 - x1
    let dy = y2 - y1
    let distance_squared = dx * dx + dy * dy
    var signs = InlineArray[Int64, 2]()
    signs[0] = -1
    signs[1] = 1
    var candidates: Int64 = 0
    for first_index in range(2):
        for second_index in range(2):
            let first_sign = signs[first_index]
            let second_sign = signs[second_index]
            let difference = second_sign * r2 - first_sign * r1
            if distance_squared >= difference * difference:
                candidates += 1
    if r1 == 0 and r2 == 0:
        return 1
    if r1 == 0 or r2 == 0:
        let radius = r1 + r2
        if distance_squared == radius * radius:
            return 1
        return candidates / 2
    let radius_sum = r1 + r2
    let radius_difference = r1 - r2
    if distance_squared == radius_sum * radius_sum or distance_squared == radius_difference * radius_difference:
        candidates -= 1
    return candidates

@export("common_tangents_two_circles")
fn common_tangents_two_circles(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
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
       r1 < 0 or r1 > MAX_RADIUS or r2 < 0 or r2 > MAX_RADIUS or
       (x1 == x2 and y1 == y2):
        return -1
    return count_tangents(x1, y1, r1, x2, y2, r2)
