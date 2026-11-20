# 64-ary hierarchical bitmap predecessor set.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn wary_low_bit(bits: UInt64) -> Int:
    var low = 0
    var high = 64
    while high - low > 1:
        let middle = (low + high) // 2
        let mask = (UInt64(1) << middle) - 1
        if (bits & mask) != 0: high = middle
        else: low = middle
    return low

fn wary_high_bit(bits: UInt64) -> Int:
    var low = 0
    var high = 64
    while high - low > 1:
        let middle = (low + high) // 2
        if (bits >> middle) != 0: low = middle
        else: high = middle
    return low

fn wary_insert(inout leaf: InlineArray[UInt64, 4096], inout group: InlineArray[UInt64, 64], inout top: UInt64, key: Int) -> Int64:
    let word = key >> 6
    let bit_index = key & 63
    let bit = UInt64(1) << bit_index
    let old = leaf[word]
    if (old & bit) != 0: return 0
    if old == 0:
        let group_index = word >> 6
        let slot = word & 63
        if group[group_index] == 0: top |= UInt64(1) << group_index
        group[group_index] |= UInt64(1) << slot
    leaf[word] = old | bit
    return 1

fn wary_erase(inout leaf: InlineArray[UInt64, 4096], inout group: InlineArray[UInt64, 64], inout top: UInt64, key: Int) -> Int64:
    let word = key >> 6
    let bit_index = key & 63
    let bit = UInt64(1) << bit_index
    let old = leaf[word]
    if (old & bit) == 0: return 0
    leaf[word] = old & ~bit
    if leaf[word] == 0:
        let group_index = word >> 6
        let slot = word & 63
        group[group_index] &= ~(UInt64(1) << slot)
        if group[group_index] == 0: top &= ~(UInt64(1) << group_index)
    return 1

fn wary_successor(inout leaf: InlineArray[UInt64, 4096], inout group: InlineArray[UInt64, 64], top: UInt64, key: Int) -> Int64:
    let word = key >> 6
    let bit_index = key & 63
    let candidates = leaf[word] >> bit_index
    if candidates != 0: return Int64(word * 64 + bit_index + wary_low_bit(candidates) + 1)
    let group_index = word >> 6
    let slot = word & 63
    var later: UInt64 = 0
    if slot < 63: later = group[group_index] >> (slot + 1)
    var next_word = 0
    if later != 0:
        next_word = group_index * 64 + slot + 1 + wary_low_bit(later)
    else:
        if group_index < 63: later = top >> (group_index + 1)
        else: later = 0
        if later == 0: return 0
        let next_group = group_index + 1 + wary_low_bit(later)
        next_word = next_group * 64 + wary_low_bit(group[next_group])
    return Int64(next_word * 64 + wary_low_bit(leaf[next_word]) + 1)

fn wary_predecessor(inout leaf: InlineArray[UInt64, 4096], inout group: InlineArray[UInt64, 64], top: UInt64, key: Int) -> Int64:
    let word = key >> 6
    let bit_index = key & 63
    let candidates = leaf[word] & ((UInt64(1) << bit_index) - 1)
    if candidates != 0: return Int64(word * 64 + wary_high_bit(candidates) + 1)
    let group_index = word >> 6
    let slot = word & 63
    var earlier = group[group_index] & ((UInt64(1) << slot) - 1)
    var previous_word = 0
    if earlier != 0:
        previous_word = group_index * 64 + wary_high_bit(earlier)
    else:
        earlier = top & ((UInt64(1) << group_index) - 1)
        if earlier == 0: return 0
        let previous_group = wary_high_bit(earlier)
        previous_word = previous_group * 64 + wary_high_bit(group[previous_group])
    return Int64(previous_word * 64 + wary_high_bit(leaf[previous_word]) + 1)

@export("w_ary_predecessor_set")
fn w_ary_predecessor_set(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 66: return -1
    let qr = input[0]
    if qr < 0 or qr > 32: return -1
    let q = Int(qr)
    if length != c_size_t(1 + 2 * q): return -1
    var leaf = InlineArray[UInt64, 4096](fill=0)
    var group = InlineArray[UInt64, 64](fill=0)
    var top: UInt64 = 0
    var result: Int64 = 0
    var cursor = 1
    for i in range(q):
        let opcode = input[cursor]
        let raw_key = input[cursor + 1]
        cursor += 2
        if opcode < 0 or opcode > 4 or raw_key < 0 or raw_key >= 262144: return -1
        let key = Int(raw_key)
        var answer: Int64 = 0
        if opcode == 0: answer = wary_insert(leaf, group, top, key)
        elif opcode == 1: answer = wary_erase(leaf, group, top, key)
        elif opcode == 2:
            if (leaf[key >> 6] & (UInt64(1) << (key & 63))) != 0: answer = 1
        elif opcode == 3: answer = wary_successor(leaf, group, top, key)
        else: answer = wary_predecessor(leaf, group, top, key)
        result += Int64(i + 1) * answer
    return result
