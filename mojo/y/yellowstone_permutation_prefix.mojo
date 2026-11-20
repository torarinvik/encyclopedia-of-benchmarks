from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N: Int64 = 64
const MIN_CAP: Int64 = 3
const MAX_CAP: Int64 = 256
const MAX_PARSEABLE_LENGTH = 3

fn ypp_gcd(left_value: Int64, right_value: Int64) -> Int64:
    var left = left_value
    var right = right_value
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

@export("yellowstone_permutation_prefix")
fn yellowstone_permutation_prefix(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 2:
        return -1
    let requested = input[0]
    let candidate_cap = input[1]
    if requested < 1 or requested > MAX_N or candidate_cap < MIN_CAP or candidate_cap > MAX_CAP:
        return -1

    var terms = InlineArray[Int64, 64](fill=0)
    var used = InlineArray[Bool, 257](fill=False)
    terms[0] = 1
    terms[1] = 2
    terms[2] = 3
    if requested <= 3:
        return terms[Int(requested) - 1]
    used[1] = True
    used[2] = True
    used[3] = True

    var term_count = 3
    while term_count < Int(requested):
        let two_back = terms[term_count - 2]
        let previous = terms[term_count - 1]
        var candidate: Int64 = 1
        while candidate <= candidate_cap:
            if not used[Int(candidate)] and ypp_gcd(candidate, two_back) > 1 and ypp_gcd(candidate, previous) == 1:
                break
            candidate += 1
        if candidate > candidate_cap:
            return -1
        terms[term_count] = candidate
        term_count += 1
        used[Int(candidate)] = True
    return terms[Int(requested) - 1]
