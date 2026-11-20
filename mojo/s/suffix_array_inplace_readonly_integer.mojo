from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_TEXT_LENGTH = 32
comptime MAX_INPUT_LENGTH = 34
comptime PACKED_FIELD_WORDS = 4
comptime PACKED_LIST_WORDS = 2

fn field_get(fields: InlineArray[UInt64, PACKED_FIELD_WORDS], index: Int) -> Int:
    let value = Int((fields[index // 9] >> ((index % 9) * 7)) & 127)
    if value == 127: return -1
    return value

fn field_set(inout fields: InlineArray[UInt64, PACKED_FIELD_WORDS], index: Int, value: Int):
    let word_index = index // 9
    let shift = (index % 9) * 7
    let mask = UInt64(127) << shift
    let encoded = UInt64(127) if value < 0 else UInt64(value)
    fields[word_index] = (fields[word_index] & ~mask) | (encoded << shift)

fn list_get(list: UnsafePointer[UInt64, MutAnyOrigin], index: Int) -> Int:
    return Int((list[index // 10] >> ((index % 10) * 6)) & 63)

fn list_set(inout list: InlineArray[UInt64, PACKED_LIST_WORDS], index: Int, value: Int):
    let word_index = index // 10
    let shift = (index % 10) * 6
    let mask = UInt64(63) << shift
    list[word_index] = (list[word_index] & ~mask) | (UInt64(value) << shift)

fn bit_is_set(bits: UInt64, index: Int) -> Bool:
    return ((bits >> index) & 1) != 0

fn bit_count(bits0: UInt64) -> Int:
    var bits = bits0
    var count = 0
    while bits != 0:
        bits &= bits - 1
        count += 1
    return count

fn bits_below(bits: UInt64, index: Int) -> Int:
    if index == 0: return 0
    let mask = (UInt64(1) << index) - 1
    return bit_count(bits & mask)

fn input_symbol(raw: UnsafePointer[Int64, ImmutAnyOrigin],
                packed: UnsafePointer[UInt64, MutAnyOrigin],
                raw_length: Int, raw_offset: Int, packed_mode: Bool,
                index: Int) -> Int:
    if not packed_mode:
        if index == raw_length: return 0
        return Int(raw[index + raw_offset]) + 1
    return list_get(packed, index)

fn sa_get(output: UnsafePointer[UInt8, MutAnyOrigin], index: Int) -> Int64:
    var bits: UInt64 = 0
    let offset = index * 8
    for byte in range(8): bits |= UInt64(output[offset + byte]) << (byte * 8)
    if (bits >> 63) != 0: return -1
    return Int64(bits)

fn sa_set(output: UnsafePointer[UInt8, MutAnyOrigin], index: Int, value: Int64):
    let offset = index * 8
    if value < 0:
        for byte in range(8): output[offset + byte] = 255
        return
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

fn build_buckets(raw: UnsafePointer[Int64, ImmutAnyOrigin],
                 packed: UnsafePointer[UInt64, ImmutAnyOrigin],
                 raw_length: Int, raw_offset: Int, packed_mode: Bool,
                 length: Int, upper: Int,
                 inout heads: InlineArray[UInt64, PACKED_FIELD_WORDS],
                 inout tails: InlineArray[UInt64, PACKED_FIELD_WORDS],
                 inout s_starts: InlineArray[UInt64, PACKED_FIELD_WORDS],
                 types: UInt64):
    var counts = InlineArray[UInt64, PACKED_FIELD_WORDS](fill=0)
    var l_counts = InlineArray[UInt64, PACKED_FIELD_WORDS](fill=0)
    var prefix = 0
    for index in range(length):
        let symbol = input_symbol(raw, packed, raw_length, raw_offset, packed_mode, index)
        field_set(counts, symbol, field_get(counts, symbol) + 1)
        if not bit_is_set(types, index):
            field_set(l_counts, symbol, field_get(l_counts, symbol) + 1)
    for symbol in range(upper + 1):
        let count = field_get(counts, symbol)
        field_set(heads, symbol, prefix)
        field_set(tails, symbol, prefix + count - 1)
        field_set(s_starts, symbol, prefix + field_get(l_counts, symbol))
        prefix += count

fn same_lms_substring(raw: UnsafePointer[Int64, ImmutAnyOrigin],
                      packed: UnsafePointer[UInt64, ImmutAnyOrigin],
                      raw_length: Int, raw_offset: Int, packed_mode: Bool,
                      length: Int, types: UInt64, lms: UInt64,
                      left: Int, right: Int) -> Bool:
    if left == right: return True
    for offset in range(length):
        let a = left + offset
        let b = right + offset
        if a >= length or b >= length or
           input_symbol(raw, packed, raw_length, raw_offset, packed_mode, a) !=
             input_symbol(raw, packed, raw_length, raw_offset, packed_mode, b) or
           bit_is_set(types, a) != bit_is_set(types, b): return False
        if offset > 0 and (bit_is_set(lms, a) or bit_is_set(lms, b)):
            return bit_is_set(lms, a) and bit_is_set(lms, b)
    return False

fn induce(raw: UnsafePointer[Int64, ImmutAnyOrigin],
          packed: UnsafePointer[UInt64, MutAnyOrigin],
          raw_length: Int, raw_offset: Int, packed_mode: Bool,
          length: Int, upper: Int, types: UInt64, lms: UInt64,
          seeds: UnsafePointer[UInt64, MutAnyOrigin], seed_count: Int,
          use_lms_mask: Bool,
          output: UnsafePointer[UInt8, MutAnyOrigin]):
    var heads = InlineArray[UInt64, PACKED_FIELD_WORDS](fill=0)
    var tails = InlineArray[UInt64, PACKED_FIELD_WORDS](fill=0)
    var s_starts = InlineArray[UInt64, PACKED_FIELD_WORDS](fill=0)
    var l_cursor = InlineArray[UInt64, PACKED_FIELD_WORDS](fill=0)
    var s_cursor = InlineArray[UInt64, PACKED_FIELD_WORDS](fill=0)
    build_buckets(raw, packed, raw_length, raw_offset, packed_mode,
                  length, upper, heads, tails, s_starts, types)
    for index in range(length): sa_set(output, index, -1)
    for symbol in range(upper + 1): field_set(s_cursor, symbol, field_get(s_starts, symbol))
    if use_lms_mask:
        for position in range(length):
            if not bit_is_set(lms, position): continue
            let symbol = input_symbol(raw, packed, raw_length, raw_offset, packed_mode, position)
            let slot = field_get(s_cursor, symbol)
            sa_set(output, slot, Int64(position))
            field_set(s_cursor, symbol, slot + 1)
    else:
        for item in range(seed_count):
            let position = list_get(seeds, item)
            let symbol = input_symbol(raw, packed, raw_length, raw_offset, packed_mode, position)
            let slot = field_get(s_cursor, symbol)
            sa_set(output, slot, Int64(position))
            field_set(s_cursor, symbol, slot + 1)
    for symbol in range(upper + 1):
        field_set(l_cursor, symbol, field_get(heads, symbol))
        field_set(s_cursor, symbol, field_get(tails, symbol) + 1)
    for slot in range(length):
        let position = sa_get(output, slot)
        if position <= 0: continue
        let previous = Int(position - 1)
        if bit_is_set(types, previous): continue
        let symbol = input_symbol(raw, packed, raw_length, raw_offset, packed_mode, previous)
        let target = field_get(l_cursor, symbol)
        sa_set(output, target, Int64(previous))
        field_set(l_cursor, symbol, target + 1)
    for slot in range(length - 1, -1, -1):
        let position = sa_get(output, slot)
        if position <= 0: continue
        let previous = Int(position - 1)
        if not bit_is_set(types, previous): continue
        let symbol = input_symbol(raw, packed, raw_length, raw_offset, packed_mode, previous)
        let target = field_get(s_cursor, symbol) - 1
        sa_set(output, target, Int64(previous))
        field_set(s_cursor, symbol, target)

fn sais_readonly(raw: UnsafePointer[Int64, ImmutAnyOrigin],
                 packed: UnsafePointer[UInt64, MutAnyOrigin],
                 raw_length: Int, raw_offset: Int, packed_mode: Bool,
                 length: Int, upper: Int,
                 output: UnsafePointer[UInt8, MutAnyOrigin]):
    if length == 0: return
    if length == 1: sa_set(output, 0, 0); return
    if length == 2:
        if input_symbol(raw, packed, raw_length, raw_offset, packed_mode, 0) >=
           input_symbol(raw, packed, raw_length, raw_offset, packed_mode, 1):
            sa_set(output, 0, 1); sa_set(output, 1, 0)
        else:
            sa_set(output, 0, 0); sa_set(output, 1, 1)
        return
    var types = UInt64(1) << (length - 1)
    for index in range(length - 2, -1, -1):
        let current = input_symbol(raw, packed, raw_length, raw_offset, packed_mode, index)
        let next = input_symbol(raw, packed, raw_length, raw_offset, packed_mode, index + 1)
        if current < next or (current == next and bit_is_set(types, index + 1)):
            types |= UInt64(1) << index
    var lms: UInt64 = 0
    var lms_positions = InlineArray[UInt64, PACKED_LIST_WORDS](fill=0)
    var lms_count = 0
    for index in range(1, length):
        if not bit_is_set(types, index - 1) and bit_is_set(types, index):
            lms |= UInt64(1) << index
            list_set(lms_positions, lms_count, index)
            lms_count += 1
    var empty_seeds = InlineArray[UInt64, PACKED_LIST_WORDS](fill=0)
    induce(raw, packed, raw_length, raw_offset, packed_mode, length, upper,
           types, lms, empty_seeds.unsafe_ptr(), 0, True, output)
    var reduced = InlineArray[UInt64, PACKED_LIST_WORDS](fill=0)
    var name = 0
    var sorted_count = 0
    var previous_lms = -1
    for slot in range(length):
        let candidate = sa_get(output, slot)
        if candidate < 0 or not bit_is_set(lms, Int(candidate)): continue
        let position = Int(candidate)
        if previous_lms >= 0 and not same_lms_substring(raw, packed, raw_length,
            raw_offset, packed_mode, length, types, lms, previous_lms, position): name += 1
        list_set(reduced, bits_below(lms, position), name)
        previous_lms = position
        sorted_count += 1
    if sorted_count != lms_count: return
    if name + 1 == lms_count:
        for ordinal in range(lms_count): sa_set(output, list_get(reduced.unsafe_ptr(), ordinal), Int64(ordinal))
    else:
        sais_readonly(raw, reduced.unsafe_ptr(), 0, 0, True, lms_count, name, output)
    var ordered_lms = InlineArray[UInt64, PACKED_LIST_WORDS](fill=0)
    for item in range(lms_count):
        let ordinal = Int(sa_get(output, item))
        list_set(ordered_lms, item, list_get(lms_positions.unsafe_ptr(), ordinal))
    induce(raw, packed, raw_length, raw_offset, packed_mode, length, upper,
           types, lms, ordered_lms.unsafe_ptr(), lms_count, False, output)

@export("suffix_array_inplace_readonly_integer")
fn suffix_array_inplace_readonly_integer(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_INPUT_LENGTH): return -1
    let count_value = input[0]
    if count_value < 0 or count_value > MAX_TEXT_LENGTH: return -1
    let count = Int(count_value)
    if length != c_size_t(count + 1): return -1
    for index in range(count):
        if input[index + 1] < 0 or input[index + 1] >= count_value: return -1
    let workspace_bytes = (count + 1) * 8
    let output_bytes = count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(workspace_bytes): return -2
    var packed_empty = InlineArray[UInt64, PACKED_LIST_WORDS](fill=0)
    sais_readonly(input, packed_empty.unsafe_ptr(), count, 1, False,
                  count + 1, count, output)
    for index in range(count):
        let position = sa_get(output, index + 1)
        sa_set(output, index, position)
    return Int64(output_bytes)
