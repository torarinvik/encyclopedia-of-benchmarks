from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N: Int64 = 30
const MAX_PARSEABLE_LENGTH = 2

@export("mian_chowla_sequence")
fn mian_chowla_sequence(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let requested = input[0]
    if length != 1 or requested < 1 or requested > MAX_N:
        return -1

    var terms = InlineArray[Int64, 30](fill=0)
    var used_sums = InlineArray[Int64, 465](fill=0)
    var term_count = 1
    var sum_count = 1
    terms[0] = 1
    used_sums[0] = 2

    while term_count < Int(requested):
        var candidate = terms[term_count - 1] + 1
        while True:
            var valid = True
            for term in range(term_count):
                let sum = candidate + terms[term]
                for old in range(sum_count):
                    if used_sums[old] == sum:
                        valid = False
                        break
                if not valid:
                    break
            if valid:
                let doubled = 2 * candidate
                for old in range(sum_count):
                    if used_sums[old] == doubled:
                        valid = False
                        break
            if valid:
                break
            candidate += 1

        for term in range(term_count):
            used_sums[sum_count] = candidate + terms[term]
            sum_count += 1
        used_sums[sum_count] = 2 * candidate
        sum_count += 1
        terms[term_count] = candidate
        term_count += 1
    return terms[Int(requested) - 1]
