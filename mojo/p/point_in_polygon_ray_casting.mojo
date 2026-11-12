from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_INPUT_LENGTH = 131
const COORDINATE_BOUND: Int64 = 1_000_000

@export("point_in_polygon_ray_casting")
fn point_in_polygon_ray_casting(values: UnsafePointer[Int64, ImmutAnyOrigin],
                                length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > MAX_INPUT_LENGTH:
        return -1
    let n = values[0]
    if n < 3 or n > 64 or length != c_size_t(3 + 2 * n):
        return -1
    let qx = values[1]
    let qy = values[2]
    if qx < -COORDINATE_BOUND or qx > COORDINATE_BOUND or qy < -COORDINATE_BOUND or qy > COORDINATE_BOUND:
        return -1
    for index in range(3, Int(length)):
        if values[index] < -COORDINATE_BOUND or values[index] > COORDINATE_BOUND:
            return -1

    var inside = False
    for index in range(Int(n)):
        let next_index = (index + 1) % Int(n)
        let ax = values[3 + 2 * index]
        let ay = values[4 + 2 * index]
        let bx = values[3 + 2 * next_index]
        let by = values[4 + 2 * next_index]
        let turn = (bx - ax) * (qy - ay) - (by - ay) * (qx - ax)
        let min_x = min(ax, bx)
        let max_x = max(ax, bx)
        let min_y = min(ay, by)
        let max_y = max(ay, by)
        if turn == 0 and qx >= min_x and qx <= max_x and qy >= min_y and qy <= max_y:
            return 1
        if (ay > qy) != (by > qy) and ((by > ay and turn > 0) or (by < ay and turn < 0)):
            inside = not inside
    return 1 if inside else 0
