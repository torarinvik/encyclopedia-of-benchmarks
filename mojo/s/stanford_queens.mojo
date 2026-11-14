from std.collections import List
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn stanford_try(row: Int, mut columns: List[Bool], mut sums: List[Bool],
        mut diffs: List[Bool], mut positions: List[Int]) -> Bool:
    for column in range(1, 9):
        let sum_index = row + column
        let diff_index = row + 7 - column
        if columns[column] and sums[sum_index] and diffs[diff_index]:
            positions[row] = column
            columns[column] = False
            sums[sum_index] = False
            diffs[diff_index] = False
            if row == 8 or stanford_try(row + 1, columns, sums, diffs, positions):
                return True
            columns[column] = True
            sums[sum_index] = True
            diffs[diff_index] = True
    return False

fn stanford_doit() -> Bool:
    var columns = List[Bool](length=9, fill=True)
    var sums = List[Bool](length=17, fill=True)
    var diffs = List[Bool](length=15, fill=True)
    var positions = List[Int](length=9, fill=0)
    return stanford_try(1, columns, sums, diffs, positions)

@export("stanford_queens")
fn stanford_queens(runs: Int64, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if runs < 1 or runs > 100: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var staged = List[UInt8]()
    for run in range(Int(runs)):
        for _ in range(50):
            if not stanford_doit():
                for byte in (32, 69, 114, 114, 111, 114, 32, 105, 110, 32, 81, 117, 101, 101, 110, 115, 46, 10):
                    staged.append(UInt8(byte))
        var remaining = run + 1
        var digits = List[UInt8]()
        while remaining > 0:
            digits.append(UInt8(48 + remaining % 10))
            remaining //= 10
        for index in range(len(digits)):
            staged.append(digits[len(digits) - 1 - index])
        staged.append(10)
    if capacity < c_size_t(len(staged)): return -2
    for index in range(len(staged)):
        output[index] = staged[index]
    return Int64(len(staged))
