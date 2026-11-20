# Clean-room bounded lexicographic successor for a one-type Dyck word.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("balanced_parenthesis_successor")
fn balanced_parenthesis_successor(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 21: return -1
    let pair_value = input[0]
    if pair_value < 1 or pair_value > 10: return -1
    let pairs = Int(pair_value)
    let sequence_length = 2 * pairs
    if length != c_size_t(1 + sequence_length): return -1
    var symbols = List[Int](capacity=sequence_length)
    var balance = 0
    for i in range(sequence_length):
        let symbol = input[1 + i]
        if symbol != 0 and symbol != 1: return -1
        if symbol == 0: balance += 1
        else: balance -= 1
        if balance < 0: return -1
        symbols.append(Int(symbol))
    if balance != 0: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(sequence_length): return -2

    var staged = List[UInt8](capacity=sequence_length)
    for _ in range(sequence_length): staged.append(UInt8(0))
    var reverse_depth = 0
    var cursor = sequence_length
    while cursor > 0:
        cursor -= 1
        if symbols[cursor] == 0: reverse_depth -= 1
        else: reverse_depth += 1
        if symbols[cursor] == 0 and reverse_depth > 0:
            reverse_depth -= 1
            let suffix_length = sequence_length - cursor - 1
            let opening_count = (suffix_length - reverse_depth) / 2
            let closing_count = suffix_length - opening_count
            for j in range(cursor): staged[j] = UInt8(40 if symbols[j] == 0 else 41)
            staged[cursor] = UInt8(41)
            var position = cursor + 1
            for _ in range(opening_count):
                staged[position] = UInt8(40)
                position += 1
            for _ in range(closing_count):
                staged[position] = UInt8(41)
                position += 1
            for j in range(sequence_length): output[j] = staged[j]
            return Int64(sequence_length)
    return -3
