from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_CELLS = 64
alias MAX_INPUT = 1095

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[word * 8 + byte] = UInt8(bits & 255)
        bits = bits >> 8

@export("forest_fire_synchronous_stochastic_ca")
fn forest_fire_synchronous_stochastic_ca(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > c_size_t(MAX_INPUT):
        return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8 or input[2] < 0 or input[2] > 8:
        return -1
    if input[3] != 10000 or input[4] < 0 or input[4] > 10000 or input[5] < 0 or input[5] > 10000:
        return -1
    let rows = Int(input[0])
    let cols = Int(input[1])
    let steps = Int(input[2])
    let cells = rows * cols
    if length != c_size_t(6 + cells + 2 * steps * cells):
        return -1
    for i in range(cells):
        if input[6 + i] < 0 or input[6 + i] > 2:
            return -1
    for row in range(rows):
        for col in range(cols):
            if (row == 0 or row == rows - 1 or col == 0 or col == cols - 1) and input[6 + row * cols + col] != 0:
                return -1
    let tape = 6 + cells
    for i in range(2 * steps * cells):
        if input[tape + i] < 0 or input[tape + i] >= 10000:
            return -1
    let bytes = (1 + 3 * steps + cells) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2

    var current = InlineArray[UInt8, MAX_CELLS](fill=0)
    var next = InlineArray[UInt8, MAX_CELLS](fill=0)
    for i in range(cells): current[i] = UInt8(input[6 + i])
    put_word(output, 0, Int64(steps))
    for tick in range(steps):
        for row in range(rows):
            for col in range(cols):
                let site = row * cols + col
                if row == 0 or row == rows - 1 or col == 0 or col == cols - 1:
                    next[site] = 0
                elif current[site] == 2:
                    next[site] = 0
                elif current[site] == 0:
                    next[site] = 1 if input[tape + tick * cells + site] < input[4] else 0
                else:
                    var near_fire = False
                    for r in range(max(0, row - 1), min(rows, row + 2)):
                        for c in range(max(0, col - 1), min(cols, col + 2)):
                            if (r != row or c != col) and current[r * cols + c] == 2:
                                near_fire = True
                    let strike = input[tape + steps * cells + tick * cells + site]
                    next[site] = 2 if near_fire or strike < input[5] else 1
        var totals = InlineArray[Int64, 3](fill=0)
        for i in range(cells): totals[Int(next[i])] += 1
        let base = 1 + 3 * tick
        for state in range(3): put_word(output, base + state, totals[state])
        for i in range(cells): current[i] = next[i]
    let final_base = 1 + 3 * steps
    for i in range(cells): put_word(output, final_base + i, Int64(current[i]))
    Int64(bytes)
