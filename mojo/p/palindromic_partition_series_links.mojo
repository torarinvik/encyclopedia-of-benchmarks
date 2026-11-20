from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_TEXT = 64
const MAX_NODES = MAX_TEXT + 2
const ALPHABET = 4
const MAX_WORDS = MAX_TEXT + 1
const MAX_OUTPUT_BYTES = MAX_WORDS * 8

fn find_extendable(
    lengths: InlineArray[Int, MAX_NODES],
    links: InlineArray[Int, MAX_NODES],
    text: InlineArray[Int, MAX_TEXT],
    position: Int,
    start: Int,
) -> Int:
    var node = start
    while True:
        let preceding = position - 1 - lengths[node]
        if preceding >= 0 and text[preceding] == text[position]:
            return node
        node = links[node]

fn put_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("palindromic_partition_series_links")
fn palindromic_partition_series_links(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_TEXT + 2):
        return -1
    if input[0] < 0 or input[0] > Int64(MAX_TEXT): return -1
    let n = Int(input[0])
    if Int(length) != n + 1: return -1
    var text = InlineArray[Int, MAX_TEXT](fill=0)
    for position in range(n):
        let symbol = input[position + 1]
        if symbol < 0 or symbol >= Int64(ALPHABET): return -1
        text[position] = Int(symbol)

    var pal_length = InlineArray[Int, MAX_NODES](fill=0)
    var suffix_link = InlineArray[Int, MAX_NODES](fill=0)
    var difference = InlineArray[Int, MAX_NODES](fill=0)
    var series_link = InlineArray[Int, MAX_NODES](fill=1)
    var series_best = InlineArray[Int, MAX_NODES](fill=0)
    var series_start = InlineArray[Int, MAX_NODES](fill=0)
    var transition = InlineArray[Int, MAX_NODES * ALPHABET](fill=0)
    pal_length[0] = 0
    pal_length[1] = -1
    suffix_link[0] = 1
    suffix_link[1] = 1
    var node_count = 2
    var last = 0
    var dp = InlineArray[Int, MAX_TEXT + 1](fill=MAX_TEXT + 1)
    var predecessor = InlineArray[Int, MAX_TEXT + 1](fill=0)
    dp[0] = 0

    for position in range(n):
        let end = position + 1
        let symbol = text[position]
        let parent = find_extendable(pal_length, suffix_link, text, position, last)
        let transition_index = parent * ALPHABET + symbol
        var next = transition[transition_index]
        if next == 0:
            next = node_count
            node_count += 1
            pal_length[next] = pal_length[parent] + 2
            transition[transition_index] = next
            if pal_length[next] == 1:
                suffix_link[next] = 0
            else:
                let suffix_parent = find_extendable(
                    pal_length, suffix_link, text, position, suffix_link[parent]
                )
                suffix_link[next] = transition[suffix_parent * ALPHABET + symbol]
            let fail = suffix_link[next]
            difference[next] = pal_length[next] - pal_length[fail]
            if difference[next] == difference[fail]:
                series_link[next] = series_link[fail]
            else:
                series_link[next] = fail
        last = next

        var best_value = MAX_TEXT + 1
        var best_start = end
        var node = last
        while pal_length[node] > 0:
            let start = end - pal_length[series_link[node]] - difference[node]
            series_best[node] = dp[start]
            series_start[node] = start
            let fail = suffix_link[node]
            if difference[node] == difference[fail] and (
                series_best[fail] < series_best[node] or
                (series_best[fail] == series_best[node] and series_start[fail] < series_start[node])
            ):
                series_best[node] = series_best[fail]
                series_start[node] = series_start[fail]
            let candidate = series_best[node] + 1
            if candidate < best_value or (candidate == best_value and series_start[node] < best_start):
                best_value = candidate
                best_start = series_start[node]
            node = series_link[node]
        dp[end] = best_value
        predecessor[end] = best_start

    var reverse_pieces = InlineArray[Int, MAX_TEXT](fill=0)
    var piece_count = 0
    var end = n
    while end > 0:
        reverse_pieces[piece_count] = end - predecessor[end]
        piece_count += 1
        end = predecessor[end]
    var words = InlineArray[Int64, MAX_WORDS](fill=0)
    var word_count = 0
    words[word_count] = Int64(piece_count)
    word_count += 1
    for index in range(piece_count):
        words[word_count] = Int64(reverse_pieces[piece_count - 1 - index])
        word_count += 1
    let bytes = word_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes: return -2
    for word in range(word_count): put_i64(output, word * 8, words[word])
    return Int64(bytes)
