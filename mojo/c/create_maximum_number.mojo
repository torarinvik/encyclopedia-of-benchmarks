from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_SOURCE_LENGTH = 6
comptime MAX_INPUT_LENGTH = 16
comptime MAX_OUTPUT_LENGTH = 12

struct Sequence:
    var values: InlineArray[UInt8, MAX_OUTPUT_LENGTH] = InlineArray[UInt8, MAX_OUTPUT_LENGTH](fill=0)
    var length: Int = 0

fn maximum_subsequence(input: UnsafePointer[Int64, ImmutAnyOrigin],
                       base: Int, length: Int, requested: Int) -> Sequence:
    var stack = InlineArray[UInt8, MAX_SOURCE_LENGTH](fill=0)
    var stack_length = 0
    var deletions = length - requested
    for i in range(length):
        let digit = UInt8(input[base + i])
        while deletions > 0 and stack_length > 0 and stack[stack_length - 1] < digit:
            stack_length -= 1
            deletions -= 1
        stack[stack_length] = digit
        stack_length += 1
    stack_length -= deletions
    var selected = Sequence()
    selected.length = stack_length
    for i in range(stack_length): selected.values[i] = stack[i]
    return selected

fn compare_suffix(first: Sequence, first_at: Int, second: Sequence, second_at: Int) -> Int:
    var i = first_at
    var j = second_at
    while i < first.length and j < second.length:
        if first.values[i] != second.values[j]:
            return 1 if first.values[i] > second.values[j] else -1
        i += 1
        j += 1
    if i == first.length and j == second.length: return 0
    return -1 if i == first.length else 1

fn merge_sequences(first: Sequence, second: Sequence) -> Sequence:
    var merged = Sequence()
    var i = 0
    var j = 0
    while i < first.length or j < second.length:
        let order = compare_suffix(first, i, second, j)
        if j == second.length or (i < first.length and order >= 0):
            merged.values[merged.length] = first.values[i]
            i += 1
        else:
            merged.values[merged.length] = second.values[j]
            j += 1
        merged.length += 1
    return merged

fn greater(left: Sequence, right: Sequence) -> Bool:
    for i in range(left.length):
        if left.values[i] != right.values[i]: return left.values[i] > right.values[i]
    return False

@export("create_maximum_number")
fn create_maximum_number(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    if input[0] < 0 or input[0] > MAX_SOURCE_LENGTH or input[1] < 0 or input[1] > MAX_SOURCE_LENGTH:
        return -1
    let first_length = Int(input[0])
    let second_length = Int(input[1])
    if input[2] < 0 or input[2] > first_length + second_length: return -1
    let requested = Int(input[2])
    if length != c_size_t(3 + first_length + second_length): return -1
    for i in range(first_length + second_length):
        let digit = input[3 + i]
        if digit < 0 or digit > 9: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(requested): return -2

    let minimum_first = max(0, requested - second_length)
    let maximum_first = min(requested, first_length)
    var best = Sequence()
    var have_best = False
    for take_first in range(minimum_first, maximum_first + 1):
        let first = maximum_subsequence(input, 3, first_length, take_first)
        let second = maximum_subsequence(input, 3 + first_length, second_length, requested - take_first)
        let candidate = merge_sequences(first, second)
        if not have_best or greater(candidate, best):
            best = candidate
            have_best = True
    for i in range(requested): output[i] = best.values[i]
    return Int64(requested)
