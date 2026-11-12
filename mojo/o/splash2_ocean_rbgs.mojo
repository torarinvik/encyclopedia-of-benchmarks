from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_CELLS = 64
alias MAX_INPUT = 132

@export("splash2_ocean_rbgs")
fn splash2_ocean_rbgs(input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
                      output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 3 or input_length > c_size_t(MAX_INPUT):
        return -1
    for i in range(input_length):
        if input[i] != input[i]: return -1
    let side_value = input[0]
    if side_value != 4.0 and side_value != 6.0 and side_value != 8.0: return -1
    let side = Int(side_value)
    let cells = side * side
    if input_length != c_size_t(3 + 2 * cells): return -1
    let eigenvalue_squared = input[1]
    let spacing = input[2]
    if eigenvalue_squared < 0.0 or eigenvalue_squared > 2.0 or spacing < 0.125 or spacing > 1.0:
        return -1
    let factor = 4.0 - eigenvalue_squared * spacing * spacing
    if factor <= 0.0: return -1

    var grid = InlineArray[Float64, MAX_CELLS](0.0)
    var rhs = InlineArray[Float64, MAX_CELLS](0.0)
    for i in range(cells):
        grid[i] = input[3 + i]
        rhs[i] = input[3 + cells + i]
        if grid[i] < -8.0 or grid[i] > 8.0 or rhs[i] < -8.0 or rhs[i] > 8.0:
            return -1
    let needed = 1 + cells
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(needed):
        return -2

    var max_change = 0.0
    for color in range(2):
        for row in range(1, side - 1):
            for column in range(1, side - 1):
                if (row + column) % 2 != color: continue
                let index = row * side + column
                let neighbors = grid[index + 1] + grid[index - 1] + grid[index - side] + grid[index + side]
                let old_value = grid[index]
                let updated = (neighbors - rhs[index]) / factor
                let difference = old_value - updated
                let change = difference if difference >= 0.0 else -difference
                if change > max_change: max_change = change
                grid[index] = updated
    output[0] = max_change
    for i in range(cells): output[i + 1] = grid[i]
    return Int64(needed)
