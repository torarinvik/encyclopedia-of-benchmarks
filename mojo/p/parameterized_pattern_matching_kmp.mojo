from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_TEXT = 64
alias MAX_PATTERN = 16
alias MAX_ALPHABET = 16
alias MAX_PARSEABLE_INPUT = 84
alias MAX_OUTPUT_BYTES = 520

fn pkmp_pattern_pair(pattern: InlineArray[Int64, MAX_PATTERN],
                     previous: InlineArray[Int, MAX_PATTERN],
                     current: Int, prefix_position: Int) -> Bool:
    let prior = previous[current]
    if prior < 0 or current - prior > prefix_position:
        return previous[prefix_position] < 0
    let distance = current - prior
    return pattern[prefix_position] == pattern[prefix_position - distance]

fn pkmp_text_pair(text: InlineArray[Int64, MAX_TEXT], text_position: Int,
                  pattern_position: Int,
                  previous: InlineArray[Int, MAX_PATTERN],
                  last_text: InlineArray[Int, MAX_ALPHABET]) -> Bool:
    let prior = previous[pattern_position]
    let symbol = Int(text[text_position])
    if prior < 0:
        return last_text[symbol] < text_position - pattern_position
    let distance = pattern_position - prior
    return text[text_position] == text[text_position - distance]

fn pkmp_store(inout bytes: InlineArray[UInt8, MAX_OUTPUT_BYTES], word: Int,
              value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        bytes[word * 8 + byte] = UInt8(bits & 255)
        bits >>= 8

@export("parameterized_pattern_matching_kmp")
fn parameterized_pattern_matching_kmp(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_PARSEABLE_INPUT:
        return -1
    let n64 = input[0]
    let m64 = input[1]
    let alphabet64 = input[2]
    if n64 < 0 or n64 > MAX_TEXT or m64 < 1 or m64 > MAX_PATTERN or
       alphabet64 < 1 or alphabet64 > MAX_ALPHABET:
        return -1
    let n = Int(n64)
    let m = Int(m64)
    let alphabet_size = Int(alphabet64)
    if length != c_size_t(3 + n + m): return -1

    var text = InlineArray[Int64, MAX_TEXT](fill=0)
    var pattern = InlineArray[Int64, MAX_PATTERN](fill=0)
    for i in range(n + m):
        let symbol = input[3 + i]
        if symbol < 0 or symbol >= Int64(alphabet_size): return -1
        if i < n:
            text[i] = symbol
        else:
            pattern[i - n] = symbol

    var previous = InlineArray[Int, MAX_PATTERN](fill=-1)
    var last_pattern = InlineArray[Int, MAX_ALPHABET](fill=-1)
    for i in range(m):
        let symbol = Int(pattern[i])
        previous[i] = last_pattern[symbol]
        last_pattern[symbol] = i

    var failure = InlineArray[Int, MAX_PATTERN](fill=0)
    for current in range(1, m):
        var matched = failure[current - 1]
        while matched > 0 and not pkmp_pattern_pair(pattern, previous, current, matched):
            matched = failure[matched - 1]
        if pkmp_pattern_pair(pattern, previous, current, matched): matched += 1
        failure[current] = matched

    var last_text = InlineArray[Int, MAX_ALPHABET](fill=-1)
    var matches = InlineArray[Int64, MAX_TEXT](fill=0)
    var match_count = 0
    var matched = 0
    if m <= n:
        for text_position in range(n):
            while True:
                if pkmp_text_pair(text, text_position, matched, previous, last_text):
                    matched += 1
                    if matched == m:
                        matches[match_count] = Int64(text_position + 1 - m)
                        match_count += 1
                        matched = failure[m - 1]
                    break
                if matched == 0: break
                matched = failure[matched - 1]
            last_text[Int(text[text_position])] = text_position

    let output_bytes = 8 * (match_count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    var staged = InlineArray[UInt8, MAX_OUTPUT_BYTES](fill=0)
    pkmp_store(staged, 0, Int64(match_count))
    for i in range(match_count):
        pkmp_store(staged, i + 1, matches[i])
    for i in range(output_bytes): output[i] = staged[i]
    return Int64(output_bytes)
