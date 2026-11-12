from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_SEQUENCE_LENGTH = 64
comptime MAX_INPUT_LENGTH = 132

fn hlc_row(input: UnsafePointer[Int64, ImmutAnyOrigin], a_base: Int,
           a0: Int, a1: Int, b_base: Int, b0: Int, b1: Int,
           reverse_a: Bool, reverse_b: Bool,
           inout row: InlineArray[Int32, MAX_SEQUENCE_LENGTH + 1]):
    let width = b1 - b0
    for j in range(width + 1): row[j] = 0
    for i in range(a1 - a0):
        let av = input[a_base + (a1 - 1 - i if reverse_a else a0 + i)]
        var diagonal: Int32 = 0
        for j in range(1, width + 1):
            let above = row[j]
            let bv = input[b_base + (b1 - j if reverse_b else b0 + j - 1)]
            if av == bv: row[j] = diagonal + 1
            elif row[j - 1] > row[j]: row[j] = row[j - 1]
            diagonal = above

fn hlc_recover(input: UnsafePointer[Int64, ImmutAnyOrigin],
               a_base: Int, a0: Int, a1: Int,
               b_base: Int, b0: Int, b1: Int,
               inout forward: InlineArray[Int32, MAX_SEQUENCE_LENGTH + 1],
               inout backward: InlineArray[Int32, MAX_SEQUENCE_LENGTH + 1],
               inout result: InlineArray[UInt8, MAX_SEQUENCE_LENGTH],
               inout result_length: Int):
    let a_length = a1 - a0
    let b_length = b1 - b0
    if a_length == 0 or b_length == 0: return
    if a_length == 1:
        let target = input[a_base + a0]
        for j in range(b0, b1):
            if input[b_base + j] == target:
                result[result_length] = UInt8(target)
                result_length += 1
                return
        return

    let middle = a0 + a_length // 2
    hlc_row(input, a_base, a0, middle, b_base, b0, b1, False, False, forward)
    hlc_row(input, a_base, middle, a1, b_base, b0, b1, True, True, backward)
    var split = 0
    var best_score: Int32 = -1
    for j in range(b_length + 1):
        let score = forward[j] + backward[b_length - j]
        if score > best_score:
            best_score = score
            split = j
    hlc_recover(input, a_base, a0, middle, b_base, b0, b0 + split,
                forward, backward, result, result_length)
    hlc_recover(input, a_base, middle, a1, b_base, b0 + split, b1,
                forward, backward, result, result_length)

@export("hirschberg_lcs")
fn hirschberg_lcs(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    if input[0] < 0 or input[0] > MAX_SEQUENCE_LENGTH or input[1] < 0 or input[1] > MAX_SEQUENCE_LENGTH:
        return -1
    let first_length = Int(input[0])
    let second_length = Int(input[1])
    if length != c_size_t(2 + first_length + second_length): return -1
    for i in range(first_length + second_length):
        let value = input[2 + i]
        if value < 0 or value > 127: return -1

    let a_base = 2 if first_length >= second_length else 2 + first_length
    let b_base = 2 + first_length if first_length >= second_length else 2
    let a_length = max(first_length, second_length)
    let b_length = min(first_length, second_length)
    var forward = InlineArray[Int32, MAX_SEQUENCE_LENGTH + 1](fill=0)
    var backward = InlineArray[Int32, MAX_SEQUENCE_LENGTH + 1](fill=0)
    var result = InlineArray[UInt8, MAX_SEQUENCE_LENGTH](fill=0)
    var result_length = 0
    hlc_recover(input, a_base, 0, a_length, b_base, 0, b_length,
                forward, backward, result, result_length)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(result_length): return -2
    for i in range(result_length): output[i] = result[i]
    return Int64(result_length)
