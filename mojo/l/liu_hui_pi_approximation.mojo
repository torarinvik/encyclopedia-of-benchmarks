from std.math import sqrt
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer


@export("liu_hui_pi_approximation")
fn liu_hui_pi_approximation(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1
    let doublings = values[0]
    if doublings < 0 or doublings > 16:
        return -1

    var sides: Int64 = 6
    var side: Float64 = 1.0
    var apothem: Float64 = sqrt(0.75)
    for _ in range(doublings):
        let half_side = side / 2.0
        let height = 1.0 - apothem
        side = sqrt(half_side * half_side + height * height)
        sides = sides * 2
        let next_half_side = side / 2.0
        apothem = sqrt(1.0 - next_half_side * next_half_side)

    let area = Float64(sides) * side * apothem / 2.0
    return Int64(area * 1000000.0 + 0.5)
