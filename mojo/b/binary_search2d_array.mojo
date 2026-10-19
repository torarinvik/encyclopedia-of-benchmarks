from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn row_search(a: UnsafePointer[Int64, ImmutAnyOrigin], base: Int, low_in: Int, high_in: Int, target: Int64) -> Int:
    var low = low_in; var high = high_in
    while low <= high:
        let mid = low + (high - low) // 2; let value = a[3 + base + mid]
        if value == target: return mid
        if value < target: low = mid + 1
        else: high = mid - 1
    return -1

@export("binary_search2d_array")
fn binary_search2d_array(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let rv = input[0]; let cv = input[1]; let target = input[2]
    if rv < 2 or rv > 32 or cv < 3 or cv > 32 or target < -2_147_483_648 or target > 2_147_483_647 or length != c_size_t(3 + rv * cv): return -1
    let rows = Int(rv); let cols = Int(cv); let midcol = cols // 2
    for i in range(rows * cols):
        if input[3 + i] < -2_147_483_648 or input[3 + i] > 2_147_483_647: return -1
    var start = 0; var end = rows - 1
    while start < end - 1:
        let mid = start + (end - start) // 2; let value = input[3 + mid * cols + midcol]
        if value == target: return Int64(mid * cols + midcol)
        if value < target: start = mid
        else: end = mid
    if input[3 + start * cols + midcol] == target: return Int64(start * cols + midcol)
    if input[3 + end * cols + midcol] == target: return Int64(end * cols + midcol)
    if target <= input[3 + start * cols + midcol - 1]:
        let c = row_search(input, start * cols, 0, midcol - 1, target)
        return Int64(start * cols + c) if c >= 0 else -1
    if target >= input[3 + start * cols + midcol + 1] and target <= input[3 + start * cols + cols - 1]:
        let c = row_search(input, start * cols, midcol + 1, cols - 1, target)
        return Int64(start * cols + c) if c >= 0 else -1
    if target <= input[3 + end * cols + midcol - 1]:
        let c = row_search(input, end * cols, 0, midcol - 1, target)
        return Int64(end * cols + c) if c >= 0 else -1
    let c = row_search(input, end * cols, midcol + 1, cols - 1, target)
    return Int64(end * cols + c) if c >= 0 else -1
