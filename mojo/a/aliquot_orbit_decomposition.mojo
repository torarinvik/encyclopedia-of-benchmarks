from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_TERMS = 4097
const MAX_INPUT = 3
const MAX_SEED = 100000
const MAX_VALUE = 100000
const MAX_TRANSITIONS = 4096

fn aliquot_sum(value: Int64) -> Int64:
    if value == 1: return 0
    var total: Int64 = 1
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            total += divisor
            let partner = value // divisor
            if partner != divisor: total += partner
        divisor += 1
    total

fn store_i64(output: mutable view[UInt8], offset: Int, value: Int64) -> None:
    var bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8(bits & UInt64(255))
        bits = bits >> 8

fn decompose(input: view[Int64], words: mutable view[Int64]) -> Int64:
    if input.len() != 2 or input[0] < 1 or input[0] > MAX_SEED or input[1] < 1 or input[1] > MAX_TRANSITIONS:
        return -1
    var keys = InlineArray[Int64, MAX_TERMS]()
    var first_indices = InlineArray[Int64, MAX_TERMS]()
    var key_count = 0
    var current = input[0]
    var transitions: Int64 = 0
    var positive_count: Int64 = 0
    while True:
        if current == 0:
            words[0] <- 0; words[1] <- positive_count; words[2] <- 0
            break
        var low = 0
        var high = key_count
        while low < high:
            let middle = low + (high - low) // 2
            if keys[middle] < current: low = middle + 1
            else: high = middle
        if low < key_count and keys[low] == current:
            words[0] <- 1
            words[1] <- first_indices[low]
            words[2] <- transitions - first_indices[low]
            break
        var cursor = key_count
        while cursor > low:
            keys[cursor] <- keys[cursor - 1]
            first_indices[cursor] <- first_indices[cursor - 1]
            cursor -= 1
        keys[low] <- current
        first_indices[low] <- transitions
        key_count += 1
        positive_count += 1
        if transitions >= input[1]:
            words[0] <- -3; words[1] <- transitions; words[2] <- current
            break
        let next_value = aliquot_sum(current)
        transitions += 1
        if next_value > MAX_VALUE:
            words[0] <- -2; words[1] <- transitions; words[2] <- next_value
            break
        current = next_value
    3

@export("aliquot_orbit_decomposition")
fn aliquot_orbit_decomposition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT:
        return -1
    var input_copy = InlineArray[Int64, MAX_INPUT]()
    for index in range(Int(length)):
        input_copy[index] <- input[index]
    var words = InlineArray[Int64, 3]()
    let result = decompose(input_copy[0:Int(length)], words[0:3])
    if result < 0: return result
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(24): return -2
    var output_copy = InlineArray[UInt8, 24]()
    for word in range(3): store_i64(output_copy[0:24], word * 8, words[word])
    for byte in range(24): output[byte] = output_copy[byte]
    24
