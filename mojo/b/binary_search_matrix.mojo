from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn search_sorted_row(input: UnsafePointer[Int64, ImmutAnyOrigin], base: Int, cols: Int, target: Int64) -> Int:
    var low = 0; var high = cols - 1
    while low <= high:
        let mid = low + (high - low) // 2; let value = input[3 + base + mid]
        if value == target: return mid
        if low >= high: return -1
        if value < target: low = mid + 1
        else: high = mid - 1
    return -1

@export("binary_search_matrix")
fn binary_search_matrix(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let rv = input[0]; let cv = input[1]; let target = input[2]
    if rv < 1 or rv > 32 or cv < 1 or cv > 32 or target < -1_000_000_000 or target > 1_000_000_000 or length != c_size_t(3 + rv * cv): return -1
    let rows = Int(rv); let cols = Int(cv)
    for i in range(rows * cols):
        if input[3 + i] < -1_000_000_000 or input[3 + i] > 1_000_000_000: return -1
    if input[3] == target: return 0
    var row = 0
    while row < rows and input[3 + row * cols] < target:
        let col = search_sorted_row(input, row * cols, cols, target)
        if col >= 0: return Int64(row * cols + col)
        row += 1
    return -1
