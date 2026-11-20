from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_COORDINATE = 1_000_000_000

@export("infinite_knight_distance")
fn infinite_knight_distance(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let dx = input[0]
    let dy = input[1]
    if dx < -MAX_COORDINATE or dx > MAX_COORDINATE or dy < -MAX_COORDINATE or dy > MAX_COORDINATE:
        return -1
    let abs_x = if dx < 0: -dx else: dx
    let abs_y = if dy < 0: -dy else: dy
    let large = if abs_x > abs_y: abs_x else: abs_y
    let small = if abs_x < abs_y: abs_x else: abs_y
    if large == 1 and small == 0: return 3
    if large == 2 and small == 2: return 4
    var distance = (large + 1) / 2
    let diagonal_bound = (large + small + 2) / 3
    if diagonal_bound > distance: distance = diagonal_bound
    if (large + small - distance) % 2 != 0: distance += 1
    return distance
