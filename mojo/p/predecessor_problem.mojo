from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_N = 4096
const MAX_WORDS = 64
const MAX_QUERIES = 512
const MAX_INPUT_LENGTH = 1090
const MAX_OUTPUT_BYTES = 4096

fn predecessor_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

fn predecessor_find_next(words: InlineArray[UInt64, MAX_WORDS], word_count: Int, n: Int, key: Int) -> Int64:
    let first_word = key // 64
    for word in range(first_word, word_count):
        let first_bit = if word == first_word then key % 64 else 0
        var candidates = words[word]
        if first_bit != 0: candidates = candidates & ((UInt64.max << first_bit))
        if candidates == 0: continue
        let end_bit = if (word + 1) * 64 < n then 64 else n - word * 64
        for bit in range(first_bit, end_bit):
            if ((candidates >> bit) & UInt64(1)) != 0: return Int64(word * 64 + bit)
    return -1

fn predecessor_find_previous(words: InlineArray[UInt64, MAX_WORDS], n: Int, key: Int) -> Int64:
    let first_word = key // 64
    var word = first_word + 1
    while word > 0:
        word -= 1
        let valid_bits = if (word + 1) * 64 > n then n - word * 64 else 64
        let requested_end = if word == first_word then key % 64 + 1 else valid_bits
        let end_bit = min(requested_end, valid_bits)
        let mask = if end_bit == 64 then UInt64.max else (UInt64(1) << end_bit) - 1
        let candidates = words[word] & mask
        if candidates == 0: continue
        var bit = end_bit
        while bit > 0:
            bit -= 1
            if ((candidates >> bit) & UInt64(1)) != 0: return Int64(word * 64 + bit)
    return -1

@export("predecessor_problem")
fn predecessor_problem(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH: return -1
    let n_value = input[0]
    let query_value = input[1]
    if n_value < 1 or n_value > MAX_N or query_value < 0 or query_value > MAX_QUERIES: return -1
    let n = Int(n_value)
    let queries = Int(query_value)
    let word_count = (n + 63) // 64
    let operation_offset = 2 + word_count
    if Int(length) != operation_offset + 2 * queries: return -1
    var words = InlineArray[UInt64, MAX_WORDS](fill=0)
    for word in range(word_count): words[word] = UInt64(input[2 + word])
    let tail_bits = n % 64
    if tail_bits != 0 and (words[word_count - 1] >> tail_bits) != 0: return -1
    for query in range(queries):
        let operation = input[operation_offset + 2 * query]
        let key = input[operation_offset + 2 * query + 1]
        if operation < 0 or operation > 4 or key < 0 or key >= n_value: return -1
    var answers = InlineArray[Int64, MAX_QUERIES](fill=0)
    var answer_count = 0
    for query in range(queries):
        let operation = input[operation_offset + 2 * query]
        let key = Int(input[operation_offset + 2 * query + 1])
        let word = key // 64
        let mask = UInt64(1) << (key % 64)
        if operation == 0: words[word] = words[word] | mask
        elif operation == 1: words[word] = words[word] & (~mask)
        elif operation == 2:
            answers[answer_count] = if (words[word] & mask) != 0 then 1 else 0
            answer_count += 1
        elif operation == 3:
            answers[answer_count] = predecessor_find_next(words, word_count, n, key)
            answer_count += 1
        else:
            answers[answer_count] = predecessor_find_previous(words, n, key)
            answer_count += 1
    let output_bytes = answer_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    var staged = InlineArray[UInt8, MAX_OUTPUT_BYTES](fill=0)
    for index in range(answer_count): predecessor_store_i64(staged.data(), index * 8, answers[index])
    for byte in range(output_bytes): output[byte] = staged[byte]
    return Int64(output_bytes)
