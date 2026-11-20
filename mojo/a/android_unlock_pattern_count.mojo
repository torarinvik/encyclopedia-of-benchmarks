from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn middle_point(first: Int, second: Int) -> Int:
    if first == second:
        return -1
    let first_x = first % 3
    let first_y = first // 3
    let second_x = second % 3
    let second_y = second // 3
    let delta_x = second_x - first_x
    let delta_y = second_y - first_y
    if delta_x % 2 != 0 or delta_y % 2 != 0:
        return -1
    let middle = ((first_y + second_y) // 2) * 3 + (first_x + second_x) // 2
    if middle == first or middle == second:
        return -1
    return middle

fn count_from(last: Int, visited: Int64, used: Int, target: Int) -> Int64:
    if used == target:
        return 1
    var count: Int64 = 0
    for next in range(9):
        let bit = Int64(1) << next
        if (visited & bit) != 0:
            continue
        let middle = middle_point(last, next)
        if middle >= 0 and (visited & (Int64(1) << middle)) == 0:
            continue
        count += count_from(next, visited | bit, used + 1, target)
    return count

@export("android_unlock_pattern_count")
fn android_unlock_pattern_count(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1
    let target_value = input[0]
    if target_value < 4 or target_value > 9:
        return -1
    let target = Int(target_value)
    var count: Int64 = 0
    for start in range(9):
        count += count_from(start, Int64(1) << start, 1, target)
    return count
