from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("interval_cover")
fn interval_cover(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 36: return -2
    let target_left = input[0]
    let target_right = input[1]
    let count_value = input[2]
    if target_left < 0 or target_left > target_right or target_right > 32 or count_value < 0 or count_value > 16: return -2
    let count = Int(count_value)
    if length != c_size_t(3 + 2 * count): return -2
    for i in range(count):
        let left = input[3 + 2 * i]
        let right = input[4 + 2 * i]
        if left < 0 or left >= right or right > 32: return -2
    if target_left == target_right: return 0

    var frontier = target_left
    var selected: Int64 = 0
    while frontier < target_right:
        var farthest = frontier
        for i in range(count):
            let left = input[3 + 2 * i]
            let right = input[4 + 2 * i]
            if left <= frontier and right > farthest: farthest = right
        if farthest == frontier: return -1
        frontier = farthest
        selected += 1
    return selected
