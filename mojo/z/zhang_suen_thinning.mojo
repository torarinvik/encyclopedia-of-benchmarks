"""Zhang-Suen thinning with simultaneous two-phase pixel deletion."""
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_ROWS = 32
comptime MAX_COLUMNS = 32
comptime MAX_CELLS = 1024

fn zst_thin_phase(inout image: InlineArray[UInt8, MAX_CELLS],
        inout marked: InlineArray[UInt8, MAX_CELLS], rows: Int,
        columns: Int, second_phase: Bool) -> Bool:
    let cells = rows * columns
    for index in range(cells):
        marked[index] = 0
    var changed = False
    for row in range(1, rows - 1):
        for column in range(1, columns - 1):
            let index = row * columns + column
            if image[index] == 0:
                continue
            let p2 = image[index - columns]
            let p3 = image[index - columns + 1]
            let p4 = image[index + 1]
            let p5 = image[index + columns + 1]
            let p6 = image[index + columns]
            let p7 = image[index + columns - 1]
            let p8 = image[index - 1]
            let p9 = image[index - columns - 1]
            var ring = InlineArray[UInt8, 9](fill=0)
            ring[0] = p2
            ring[1] = p3
            ring[2] = p4
            ring[3] = p5
            ring[4] = p6
            ring[5] = p7
            ring[6] = p8
            ring[7] = p9
            ring[8] = p2
            var black_neighbors = 0
            var transitions = 0
            for neighbor in range(8):
                black_neighbors += Int(ring[neighbor])
                if ring[neighbor] == 0 and ring[neighbor + 1] == 1:
                    transitions += 1
            if black_neighbors < 2 or black_neighbors > 6 or transitions != 1:
                continue
            var blocked = False
            if second_phase:
                blocked = (p2 != 0 and p4 != 0 and p8 != 0) or (p2 != 0 and p6 != 0 and p8 != 0)
            else:
                blocked = (p2 != 0 and p4 != 0 and p6 != 0) or (p4 != 0 and p6 != 0 and p8 != 0)
            if not blocked:
                marked[index] = 1
                changed = True
    if changed:
        for index in range(cells):
            if marked[index] != 0:
                image[index] = 0
    return changed

@export("zhang_suen_thinning")
fn zhang_suen_thinning(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 1027:
        return -1
    let rows_value = input[0]
    let columns_value = input[1]
    if rows_value < 1 or rows_value > MAX_ROWS or
            columns_value < 1 or columns_value > MAX_COLUMNS:
        return -1
    let rows = Int(rows_value)
    let columns = Int(columns_value)
    let cells = rows * columns
    if length != c_size_t(2 + cells):
        return -1
    for index in range(cells):
        if input[index + 2] != 0 and input[index + 2] != 1:
            return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(cells):
        return -2

    var image = InlineArray[UInt8, MAX_CELLS](fill=0)
    var marked = InlineArray[UInt8, MAX_CELLS](fill=0)
    for index in range(cells):
        image[index] = UInt8(input[index + 2])
    while True:
        let first_changed = zst_thin_phase(inout image, inout marked, rows, columns, False)
        let second_changed = zst_thin_phase(inout image, inout marked, rows, columns, True)
        if not first_changed and not second_changed:
            break
    for index in range(cells):
        output[index] = image[index]
    return Int64(cells)
