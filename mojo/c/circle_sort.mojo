from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn circle_sort_range(values: UnsafePointer[Int64, MutAnyOrigin], left_value: Int64, right_value: Int64) -> Bool:
    if left_value >= right_value: return False
    var low = left_value
    var high = right_value
    var swapped = False
    while low < high:
        if values[low] > values[high]:
            let temp = values[low]
            values[low] = values[high]
            values[high] = temp
            swapped = True
        low += 1
        high -= 1
    if low == high and values[low] > values[high + 1]:
        let temp = values[low]
        values[low] = values[high + 1]
        values[high + 1] = temp
        swapped = True
    let middle = left_value + (right_value - left_value) // 2
    let left_swapped = circle_sort_range(values, left_value, middle)
    let right_swapped = circle_sort_range(values, middle + 1, right_value)
    return swapped or left_swapped or right_swapped

@export("circle_sort")
fn circle_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    if length < 2: return
    var swapped = True
    while swapped:
        swapped = circle_sort_range(values, 0, Int64(length) - 1)
