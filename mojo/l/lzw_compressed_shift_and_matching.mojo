from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("lzw_compressed_shift_and_matching")
fn lzw_compressed_shift_and_matching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 67: return -1
    let alphabet_raw = input[0]
    let pattern_raw = input[1]
    let code_count_raw = input[2]
    if alphabet_raw < 1 or alphabet_raw > 16 or pattern_raw < 1 or pattern_raw > 32 or code_count_raw < 0 or code_count_raw > 32: return -1
    let alphabet = Int(alphabet_raw)
    let m = Int(pattern_raw)
    let code_count = Int(code_count_raw)
    if Int(length) != 3 + m + code_count: return -1
    var symbol_masks = InlineArray[UInt32, 16](fill=0)
    for i in range(m):
        let symbol = input[3 + i]
        if symbol < 0 or symbol >= alphabet_raw: return -1
        symbol_masks[Int(symbol)] |= UInt32(1) << i
    let codes = input + 3 + m
    if code_count > 0 and (codes[0] < 0 or codes[0] >= alphabet_raw): return -1

    var phrase_lengths = InlineArray[Int, 47](fill=0)
    var first_symbols = InlineArray[UInt8, 47](fill=0)
    var phrase_masks = InlineArray[UInt32, 47](fill=0)
    var crossing_masks = InlineArray[UInt32, 47](fill=0)
    var ends_match = InlineArray[Bool, 47](fill=False)
    var previous_match = InlineArray[Int, 47](fill=-1)
    let top_bit = UInt32(1) << (m - 1)
    for symbol in range(alphabet):
        phrase_lengths[symbol] = 1
        first_symbols[symbol] = UInt8(symbol)
        phrase_masks[symbol] = symbol_masks[symbol]
        if m > 1 and (phrase_masks[symbol] & top_bit) != 0:
            crossing_masks[symbol] = UInt32(1) << (m - 2)
        ends_match[symbol] = m == 1 and (phrase_masks[symbol] & top_bit) != 0

    var words = InlineArray[Int64, 529](fill=0)
    var occurrence_count = 0
    var node_count = alphabet
    var text_offset = 0
    var state: UInt32 = 0
    var previous_code = -1
    for token in range(code_count):
        let code_raw = codes[token]
        var current_code = 0
        if previous_code < 0:
            current_code = Int(code_raw)
        else:
            if code_raw < 0 or code_raw > Int64(node_count): return -1
            var appended: UInt8 = 0
            if code_raw == Int64(node_count):
                appended = first_symbols[previous_code]
                current_code = node_count
            else:
                current_code = Int(code_raw)
                appended = first_symbols[current_code]
            if node_count >= 47: return -1
            let node = node_count
            node_count += 1
            phrase_lengths[node] = phrase_lengths[previous_code] + 1
            first_symbols[node] = first_symbols[previous_code]
            phrase_masks[node] = ((phrase_masks[previous_code] << 1) | UInt32(1)) & symbol_masks[Int(appended)]
            crossing_masks[node] = crossing_masks[previous_code]
            if phrase_lengths[node] < m and (phrase_masks[node] & top_bit) != 0:
                crossing_masks[node] |= UInt32(1) << (m - phrase_lengths[node] - 1)
            ends_match[node] = phrase_lengths[node] >= m and (phrase_masks[node] & top_bit) != 0
            if ends_match[previous_code]:
                previous_match[node] = previous_code
            else:
                previous_match[node] = previous_match[previous_code]

        var crossing = state & crossing_masks[current_code]
        while crossing != 0:
            var highest = 0
            var bits = crossing
            while (bits >> 1) != 0:
                bits >>= 1
                highest += 1
            words[1 + occurrence_count] = Int64(text_offset - highest - 1)
            occurrence_count += 1
            crossing &= ~(UInt32(1) << highest)

        var internal_nodes = InlineArray[Int, 47](fill=0)
        var internal_count = 0
        var node = current_code if ends_match[current_code] else previous_match[current_code]
        while node >= 0:
            internal_nodes[internal_count] = node
            internal_count += 1
            node = previous_match[node]
        while internal_count > 0:
            internal_count -= 1
            node = internal_nodes[internal_count]
            words[1 + occurrence_count] = Int64(text_offset + phrase_lengths[node] - m)
            occurrence_count += 1

        let current_length = phrase_lengths[current_code]
        var shifted: UInt32 = 0
        if current_length < m: shifted = state << current_length
        var fresh: UInt32 = 0
        if current_length >= m:
            fresh = if m == 32 then UInt32(0xffffffff) else (UInt32(1) << m) - UInt32(1)
        else:
            fresh = (UInt32(1) << current_length) - UInt32(1)
        state = (shifted | fresh) & phrase_masks[current_code]
        text_offset += current_length
        previous_code = current_code

    words[0] = Int64(occurrence_count)
    let output_bytes = 8 * (occurrence_count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    for word in range(occurrence_count + 1):
        let bits = UInt64(words[word])
        for byte in range(8): output[word * 8 + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))
    return Int64(output_bytes)
