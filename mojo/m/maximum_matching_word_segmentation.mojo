from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 64
comptime MAX_WORDS = 16
comptime MAX_WORD_LENGTH = 8
comptime MAX_PARSEABLE_LENGTH = 211

@export("maximum_matching_word_segmentation")
fn maximum_matching_word_segmentation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_PARSEABLE_LENGTH):
        return -1
    let text_length_value = input[0]
    let word_count_value = input[1]
    if text_length_value < 0 or text_length_value > MAX_TEXT or word_count_value < 0 or word_count_value > MAX_WORDS:
        return -1
    let text_length = Int(text_length_value)
    let word_count = Int(word_count_value)
    if Int(length) < 2 + text_length:
        return -1
    for position in range(text_length):
        if input[2 + position] < 97 or input[2 + position] > 122:
            return -1

    var word_offsets = InlineArray[Int, MAX_WORDS](fill=0)
    var word_lengths = InlineArray[Int, MAX_WORDS](fill=0)
    var cursor = 2 + text_length
    for word in range(word_count):
        if cursor >= Int(length):
            return -1
        let word_length_value = input[cursor]
        cursor += 1
        if word_length_value < 1 or word_length_value > MAX_WORD_LENGTH:
            return -1
        let word_length = Int(word_length_value)
        if word_length > Int(length) - cursor:
            return -1
        word_offsets[word] = cursor
        word_lengths[word] = word_length
        for offset in range(word_length):
            if input[cursor + offset] < 97 or input[cursor + offset] > 122:
                return -1
        cursor += word_length
    if cursor != Int(length):
        return -1

    var token_ids = InlineArray[UInt8, MAX_TEXT](fill=0)
    var token_count = 0
    var position = 0
    while position < text_length:
        var best_length = 0
        var best_id: UInt8 = 0
        for word in range(word_count):
            let candidate_length = word_lengths[word]
            if candidate_length <= best_length or candidate_length > text_length - position:
                continue
            var offset = 0
            while offset < candidate_length and input[word_offsets[word] + offset] == input[2 + position + offset]:
                offset += 1
            if offset == candidate_length:
                best_length = candidate_length
                best_id = UInt8(word + 1)
        token_ids[token_count] = best_id
        token_count += 1
        position += best_length if best_length > 0 else 1

    let output_length = token_count + 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < output_length:
        return -2
    output[0] = UInt8(token_count)
    for token in range(token_count):
        output[token + 1] = token_ids[token]
    return Int64(output_length)
