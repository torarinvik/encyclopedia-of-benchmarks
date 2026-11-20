from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N: Int64 = 14
const MAX_CANDIDATE: Int64 = 64
const MAX_PARSEABLE_LENGTH = 2

@export("ulam_sequence_1_2")
fn ulam_sequence_1_2(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let requested = input[0]
    if length != 1 or requested < 1 or requested > MAX_N:
        return -1

    var terms = InlineArray[Int64, 14](fill=0)
    var representations = InlineArray[Int64, 75](fill=0)
    terms[0] = 1
    terms[1] = 2
    representations[3] = 1
    var term_count = 2

    while term_count < Int(requested):
        var candidate = terms[term_count - 1] + 1
        while candidate <= MAX_CANDIDATE and representations[Int(candidate)] != 1:
            candidate += 1
        if candidate > MAX_CANDIDATE:
            return -1
        for old in range(term_count):
            let sum = Int(candidate + terms[old])
            if representations[sum] < 2:
                representations[sum] += 1
        terms[term_count] = candidate
        term_count += 1
    return terms[Int(requested) - 1]
