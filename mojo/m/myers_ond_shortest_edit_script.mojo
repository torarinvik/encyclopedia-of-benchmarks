from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MYERS_MAX_SEQUENCE = 16
alias MYERS_MAX_DISTANCE = 32
alias MYERS_MAX_OUTPUT = 48
alias MYERS_OFFSET = 33
alias MYERS_DIAGONALS = 67
alias MYERS_TRACE_SIZE = 2211

fn myers_build_script(input: UnsafePointer[Int64, ImmutAnyOrigin]) -> (InlineArray[UInt8, MYERS_MAX_OUTPUT], Int):
    let n = Int(input[0])
    let m = Int(input[1])
    var frontier = InlineArray[Int32, MYERS_DIAGONALS](fill=-1)
    var trace = InlineArray[Int32, MYERS_TRACE_SIZE](fill=-1)
    frontier[MYERS_OFFSET + 1] = 0
    var found_d = -1
    var found_k = 0
    for distance in range(n + m + 1):
        var diagonal = -distance
        while diagonal <= distance:
            let slot = MYERS_OFFSET + diagonal
            var x = 0
            if diagonal == -distance or (diagonal != distance and frontier[slot - 1] < frontier[slot + 1]):
                x = Int(frontier[slot + 1])
            else:
                x = Int(frontier[slot - 1]) + 1
            var y = x - diagonal
            while x < n and y < m and input[2 + x] == input[2 + n + y]:
                x += 1
                y += 1
            frontier[slot] = Int32(x)
            trace[distance * MYERS_DIAGONALS + slot] = Int32(x)
            if x >= n and y >= m:
                found_d = distance
                found_k = diagonal
                break
            diagonal += 2
        if found_d >= 0: break

    var reverse_ops = InlineArray[UInt8, MYERS_MAX_DISTANCE](fill=0)
    var reverse_symbols = InlineArray[UInt8, MYERS_MAX_DISTANCE](fill=0)
    var path_length = 0
    var x = n
    var y = m
    var diagonal = found_k
    for layer in range(found_d, 0, -1):
        let slot = MYERS_OFFSET + diagonal
        let previous_row = (layer - 1) * MYERS_DIAGONALS
        var previous_diagonal = 0
        var previous_x = 0
        var previous_y = 0
        var snake_x = 0
        var snake_y = 0
        if diagonal == -layer or (diagonal != layer and trace[previous_row + slot - 1] < trace[previous_row + slot + 1]):
            previous_diagonal = diagonal + 1
            previous_x = Int(trace[previous_row + MYERS_OFFSET + previous_diagonal])
            previous_y = previous_x - previous_diagonal
            snake_x = previous_x
            snake_y = previous_y + 1
            while x > snake_x and y > snake_y:
                reverse_ops[path_length] = 0
                reverse_symbols[path_length] = 0
                path_length += 1
                x -= 1
                y -= 1
            reverse_ops[path_length] = 2
            reverse_symbols[path_length] = UInt8(input[2 + n + previous_y])
            path_length += 1
        else:
            previous_diagonal = diagonal - 1
            previous_x = Int(trace[previous_row + MYERS_OFFSET + previous_diagonal])
            previous_y = previous_x - previous_diagonal
            snake_x = previous_x + 1
            snake_y = previous_y
            while x > snake_x and y > snake_y:
                reverse_ops[path_length] = 0
                reverse_symbols[path_length] = 0
                path_length += 1
                x -= 1
                y -= 1
            reverse_ops[path_length] = 1
            reverse_symbols[path_length] = 0
            path_length += 1
        x = previous_x
        y = previous_y
        diagonal = previous_diagonal

    let prefix = Int(trace[MYERS_OFFSET])
    for _ in range(prefix):
        reverse_ops[path_length] = 0
        reverse_symbols[path_length] = 0
        path_length += 1
    var result = InlineArray[UInt8, MYERS_MAX_OUTPUT](fill=0)
    var written = 0
    for step_index in range(path_length):
        let step = path_length - step_index - 1
        let operation = reverse_ops[step]
        result[written] = operation
        written += 1
        if operation == 2:
            result[written] = reverse_symbols[step]
            written += 1
    return result, written

@export("myers_ond_shortest_edit_script")
fn myers_ond_shortest_edit_script(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(2 + 2 * MYERS_MAX_SEQUENCE): return -1
    let n = input[0]
    let m = input[1]
    if n < 0 or n > MYERS_MAX_SEQUENCE or m < 0 or m > MYERS_MAX_SEQUENCE: return -1
    if length != c_size_t(2 + n + m): return -1
    for i in range(Int(n + m)):
        if input[2 + i] < 0 or input[2 + i] > 255: return -1
    let (result, needed) = myers_build_script(input)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(needed): return -2
    for i in range(needed): output[i] = result[i]
    return Int64(needed)
