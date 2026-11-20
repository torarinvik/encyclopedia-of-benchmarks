from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_STATES = 8
comptime MAX_STEPS = 64
comptime MAX_INPUT = 267
comptime MAX_OUTPUT = 65

@export("metropolis_hastings_asymmetric_proposal")
fn metropolis_hastings_asymmetric_proposal(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or
        length < c_size_t(3) or length > c_size_t(MAX_INPUT):
        return -1
    let n64 = input[0]
    let steps64 = input[1]
    let initial64 = input[2]
    if n64 < 2 or n64 > MAX_STATES or steps64 < 0 or steps64 > MAX_STEPS or
        initial64 < 0 or initial64 >= n64:
        return -1
    let n = Int(n64)
    let steps = Int(steps64)
    let weights_start = 3
    let matrix_start = weights_start + n
    let proposals_start = matrix_start + n*n
    let draws_start = proposals_start + steps
    if length != c_size_t(draws_start + 2*steps):
        return -1
    for state in range(n):
        let weight = input[weights_start + state]
        if weight < 1 or weight > 1024:
            return -1
    for row in range(n):
        var row_sum: Int64 = 0
        for column in range(n):
            let q = input[matrix_start + row*n + column]
            if q < 0 or q > 1024:
                return -1
            row_sum += q
        if row_sum != 1024:
            return -1

    var staged = InlineArray[UInt8, MAX_OUTPUT](fill=0)
    var current = Int(initial64)
    staged[0] = UInt8(current)
    for step in range(steps):
        let proposal64 = input[proposals_start + step]
        let draw_num = input[draws_start + 2*step]
        let draw_den = input[draws_start + 2*step + 1]
        if proposal64 < 0 or proposal64 >= n64 or draw_den < 1 or draw_den > 1024 or
            draw_num < 0 or draw_num >= draw_den:
            return -1
        let proposal = Int(proposal64)
        let forward = input[matrix_start + current*n + proposal]
        if forward == 0:
            return -1
        let reverse = input[matrix_start + proposal*n + current]
        let numerator = input[weights_start + proposal] * reverse
        let denominator = input[weights_start + current] * forward
        if numerator >= denominator or draw_num*denominator < draw_den*numerator:
            current = proposal
        staged[step + 1] = UInt8(current)

    let needed = steps + 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed):
        return -2
    for index in range(needed):
        output[index] = staged[index]
    return Int64(needed)
