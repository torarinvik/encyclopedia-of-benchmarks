from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const EERTREE_MAX_TEXT_LENGTH: Int = 128
const EERTREE_MAX_INPUT_LENGTH: Int = EERTREE_MAX_TEXT_LENGTH + 1
const EERTREE_ALPHABET_SIZE: Int = 26
const EERTREE_MAX_NODES: Int = EERTREE_MAX_TEXT_LENGTH + 2

fn eertree_find_extendable(
    palindrome_lengths: InlineArray[Int, EERTREE_MAX_NODES],
    suffix_links: InlineArray[Int, EERTREE_MAX_NODES],
    text: InlineArray[Int64, EERTREE_MAX_TEXT_LENGTH],
    position: Int,
    start: Int,
) -> Int:
    var node = start
    while True:
        let preceding = position - 1 - palindrome_lengths[node]
        if preceding >= 0 and text[preceding] == text[position]:
            return node
        node = suffix_links[node]

@export("eertree")
fn eertree(
    values: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
) -> Int64 abi("C"):
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(EERTREE_MAX_INPUT_LENGTH):
        return -1
    if values[0] < 0 or values[0] > Int64(EERTREE_MAX_TEXT_LENGTH):
        return -1

    let text_length = Int(values[0])
    if length != c_size_t(text_length + 1):
        return -1

    var text = InlineArray[Int64, EERTREE_MAX_TEXT_LENGTH]()
    for position in range(text_length):
        let letter = values[position + 1]
        if letter < 0 or letter >= Int64(EERTREE_ALPHABET_SIZE):
            return -1
        text[position] = letter

    var palindrome_lengths = InlineArray[Int, EERTREE_MAX_NODES](fill=0)
    var suffix_links = InlineArray[Int, EERTREE_MAX_NODES](fill=0)
    var transitions = InlineArray[Int, EERTREE_MAX_NODES * EERTREE_ALPHABET_SIZE](fill=-1)
    palindrome_lengths[0] = -1

    var node_count = 2
    var longest_suffix = 1
    var checksum: Int64 = 0
    for position in range(text_length):
        let letter = Int(text[position])
        let parent = eertree_find_extendable(
            palindrome_lengths, suffix_links, text, position, longest_suffix
        )
        let parent_slot = parent * EERTREE_ALPHABET_SIZE + letter
        var next = transitions[parent_slot]
        if next < 0:
            next = node_count
            node_count += 1
            palindrome_lengths[next] = palindrome_lengths[parent] + 2
            transitions[parent_slot] = next
            if palindrome_lengths[next] == 1:
                suffix_links[next] = 1
            else:
                let suffix_parent = eertree_find_extendable(
                    palindrome_lengths,
                    suffix_links,
                    text,
                    position,
                    suffix_links[parent],
                )
                let suffix_slot = suffix_parent * EERTREE_ALPHABET_SIZE + letter
                let suffix = transitions[suffix_slot]
                if suffix < 0:
                    return -1
                suffix_links[next] = suffix

        longest_suffix = next
        checksum += Int64(position + 1) * Int64(node_count - 2)

    return checksum
