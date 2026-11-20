from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn sift_down_min(values: UnsafePointer[Int64, MutAnyOrigin], root_value: Int, end: Int) -> None:
    var root = root_value
    while root < end // 2:
        var child = root * 2 + 1
        if child + 1 < end and values[child + 1] < values[child]:
            child += 1
        if values[root] <= values[child]:
            break
        let temporary = values[root]
        values[root] = values[child]
        values[child] = temporary
        root = child

fn sift_down_max(values: UnsafePointer[Int64, MutAnyOrigin], root_value: Int, end: Int) -> None:
    var root = root_value
    while root < end // 2:
        var child = root * 2 + 1
        if child + 1 < end and values[child + 1] > values[child]:
            child += 1
        if values[root] >= values[child]:
            break
        let temporary = values[root]
        values[root] = values[child]
        values[child] = temporary
        root = child

fn reverse_values(values: UnsafePointer[Int64, MutAnyOrigin], length: Int) -> None:
    for left in range(length // 2):
        let right = length - 1 - left
        let temporary = values[left]
        values[left] = values[right]
        values[right] = temporary

@export("jsort")
fn jsort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    if values == UnsafePointer[Int64, MutAnyOrigin]() or length < 2:
        return
    let count = Int(length)
    for start in range(count // 2):
        sift_down_min(values, count // 2 - 1 - start, count)

    reverse_values(values, count)
    for start in range(count // 2):
        sift_down_max(values, count // 2 - 1 - start, count)
    reverse_values(values, count)

    for index in range(1, count):
        let key = values[index]
        var position = index
        while position > 0 and values[position - 1] > key:
            values[position] = values[position - 1]
            position -= 1
        values[position] = key
