from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("unique_occurrences")
def unique_occurrences(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if length == 0:
        return 1
    if input == None or length > 1000:
        return -1
    var values = input.value()
    var n = Int(length)
    var first = UInt64(values[unsafe_offset=0])
    if n == 1:
        return 1 if first + 1000 <= 2000 else -1

    var largest_biased: UInt64 = 0
    var different_bits: UInt64 = 0
    for index in range(n):
        var value = UInt64(values[unsafe_offset=index])
        different_bits |= value ^ first
        largest_biased = max(largest_biased, value + 1000)
    if largest_biased > 2000:
        return -1
    if different_bits == 0:
        return 1

    var counts = Array[UInt16, 2001](fill=0)
    var touched = Array[UInt16, 44](fill=0)
    var count_slots = counts.unsafe_ptr()
    var touched_slots = touched.unsafe_ptr()
    var distinct = 0
    for index in range(n):
        var slot = Int(values[unsafe_offset=index] + 1000)
        if count_slots[unsafe_offset=slot] == 0:
            var next_distinct = distinct + 1
            if next_distinct * (next_distinct + 1) > 2 * n:
                return 0
            touched_slots[unsafe_offset=distinct] = UInt16(slot)
            distinct = next_distinct
        count_slots[unsafe_offset=slot] += 1

    var seen = Array[UInt64, 16](fill=0)
    var seen_words = seen.unsafe_ptr()
    for index in range(distinct):
        var frequency = Int(count_slots[unsafe_offset=Int(touched_slots[unsafe_offset=index])])
        var word = frequency >> 6
        var bit = UInt64(1) << UInt64(frequency & 63)
        if (seen_words[unsafe_offset=word] & bit) != 0:
            return 0
        seen_words[unsafe_offset=word] |= bit
    return 1
