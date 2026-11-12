from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_TEXT_LENGTH = 32
comptime MAX_INPUT_LENGTH = 34
comptime MAX_ALPHABET = 256
comptime MAX_N = MAX_TEXT_LENGTH + 1

fn induce(
    symbols: InlineArray[Int32, MAX_N], length: Int, upper: Int,
    is_s: InlineArray[Bool, MAX_N],
    sum_s: InlineArray[Int32, MAX_ALPHABET + 2],
    sum_l: InlineArray[Int32, MAX_ALPHABET + 2],
    ordered_lms: InlineArray[Int32, MAX_N], lms_count: Int,
) -> InlineArray[Int32, MAX_N]:
    var suffixes = InlineArray[Int32, MAX_N](fill=-1)
    var bucket = InlineArray[Int32, MAX_ALPHABET + 2](fill=0)
    for i in range(upper + 2): bucket[i] = sum_s[i]
    for i in range(length):
        suffixes[i] = -1
    for i in range(lms_count):
        let position = Int(ordered_lms[i])
        let symbol = Int(symbols[position])
        suffixes[Int(bucket[symbol])] = Int32(position)
        bucket[symbol] += 1
    for i in range(upper + 2): bucket[i] = sum_l[i]
    for i in range(length):
        let position = Int(suffixes[i])
        if position > 0 and not is_s[position - 1]:
            let symbol = Int(symbols[position - 1])
            suffixes[Int(bucket[symbol])] = Int32(position - 1)
            bucket[symbol] += 1
    for i in range(upper + 2): bucket[i] = sum_l[i]
    for i in range(length - 1, -1, -1):
        let position = Int(suffixes[i])
        if position > 0 and is_s[position - 1]:
            let symbol = Int(symbols[position - 1]) + 1
            bucket[symbol] -= 1
            suffixes[Int(bucket[symbol])] = Int32(position - 1)
    return suffixes

fn same_lms_substring(
    symbols: InlineArray[Int32, MAX_N], length: Int,
    is_s: InlineArray[Bool, MAX_N],
    lms_map: InlineArray[Int32, MAX_N + 1], left: Int, right: Int,
) -> Bool:
    if left == right: return True
    var offset = 0
    while offset < length:
        let a = left + offset
        let b = right + offset
        if a >= length or b >= length or symbols[a] != symbols[b] or is_s[a] != is_s[b]:
            return False
        let a_lms = offset > 0 and lms_map[a] >= 0
        let b_lms = offset > 0 and lms_map[b] >= 0
        if a_lms or b_lms: return a_lms and b_lms
        offset += 1
    return False

fn sais(
    symbols: InlineArray[Int32, MAX_N], length: Int, upper: Int,
) -> InlineArray[Int32, MAX_N]:
    var suffixes = InlineArray[Int32, MAX_N](fill=0)
    if length == 0: return suffixes
    if length <= 2:
        for i in range(length): suffixes[i] = Int32(i)
        if length == 2 and symbols[0] >= symbols[1]:
            suffixes[0] = 1
            suffixes[1] = 0
        return suffixes

    var is_s = InlineArray[Bool, MAX_N](fill=False)
    is_s[length - 1] = True
    for i in range(length - 2, -1, -1):
        is_s[i] = symbols[i] < symbols[i + 1] or (symbols[i] == symbols[i + 1] and is_s[i + 1])

    var lms_map = InlineArray[Int32, MAX_N + 1](fill=-1)
    var lms = InlineArray[Int32, MAX_N](fill=0)
    var lms_count = 0
    for i in range(1, length):
        if not is_s[i - 1] and is_s[i]:
            lms_map[i] = Int32(lms_count)
            lms[lms_count] = Int32(i)
            lms_count += 1

    var sum_s = InlineArray[Int32, MAX_ALPHABET + 2](fill=0)
    var sum_l = InlineArray[Int32, MAX_ALPHABET + 2](fill=0)
    for i in range(length):
        let symbol = Int(symbols[i])
        if is_s[i]: sum_l[symbol + 1] += 1
        else: sum_s[symbol] += 1
    for symbol in range(upper + 1):
        sum_s[symbol] += sum_l[symbol]
        sum_l[symbol + 1] += sum_s[symbol]

    suffixes = induce(symbols, length, upper, is_s, sum_s, sum_l, lms, lms_count)
    var sorted_lms = InlineArray[Int32, MAX_N](fill=0)
    var sorted_count = 0
    for i in range(length):
        let position = Int(suffixes[i])
        if position >= 0 and lms_map[position] >= 0:
            sorted_lms[sorted_count] = Int32(position)
            sorted_count += 1

    var reduced = InlineArray[Int32, MAX_N](fill=0)
    var reduced_upper = 0
    for i in range(sorted_count):
        if i > 0 and not same_lms_substring(
            symbols, length, is_s, lms_map,
            Int(sorted_lms[i - 1]), Int(sorted_lms[i]),
        ):
            reduced_upper += 1
        reduced[Int(lms_map[Int(sorted_lms[i])])] = Int32(reduced_upper)

    var reduced_order = InlineArray[Int32, MAX_N](fill=0)
    if reduced_upper + 1 == sorted_count:
        for i in range(sorted_count): reduced_order[Int(reduced[i])] = Int32(i)
    else:
        reduced_order = sais(reduced, sorted_count, reduced_upper)
    var ordered_lms = InlineArray[Int32, MAX_N](fill=0)
    for i in range(sorted_count): ordered_lms[i] = lms[Int(reduced_order[i])]
    return induce(symbols, length, upper, is_s, sum_s, sum_l, ordered_lms, sorted_count)

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("suffix_array_sais")
fn suffix_array_sais(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let count_value = input[0]
    if count_value < 0 or count_value > MAX_TEXT_LENGTH: return -1
    let count = Int(count_value)
    if length != c_size_t(count + 1): return -1
    for i in range(count):
        if input[i + 1] < 0 or input[i + 1] > 255: return -1
    let output_bytes = count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    var symbols = InlineArray[Int32, MAX_N](fill=0)
    for i in range(count): symbols[i] = Int32(input[i + 1] + 1)
    symbols[count] = 0
    let suffixes = sais(symbols, count + 1, MAX_ALPHABET)
    var out = 0
    for i in range(count + 1):
        if Int(suffixes[i]) == count: continue
        store_i64_le(output, out * 8, Int64(suffixes[i]))
        out += 1
    return Int64(output_bytes)
