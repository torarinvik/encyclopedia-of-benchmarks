from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("ekg_sequence")
fn ekg_sequence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin],
                capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 2:
        return -1
    let requested = input[0]
    if length != 1 or requested < 1 or requested > 8:
        return -1

    var terms = InlineArray[Int64, 8](fill=0)
    var used = InlineArray[UInt8, 40321](fill=0)
    terms[0] = 1
    used[1] = 1
    var term_count = 1
    if requested >= 2:
        terms[1] = 2
        used[2] = 1
        term_count = 2

    while term_count < Int(requested):
        let position = Int64(term_count + 1)
        let previous = terms[term_count - 1]
        let search_bound = previous * position
        var candidate: Int64 = 1
        while candidate <= search_bound:
            if used[Int(candidate)] == 0 and gcd_i64(previous, candidate) > 1:
                break
            candidate += 1
        if candidate > search_bound:
            return -1
        terms[term_count] = candidate
        used[Int(candidate)] = 1
        term_count += 1

    let output_bytes = Int(requested) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for index in range(term_count):
        let bits = UInt64(terms[index])
        for byte in range(8):
            output[index * 8 + byte] = UInt8((bits >> (byte * 8)) & 255)
    return Int64(output_bytes)

fn gcd_i64(left: Int64, right: Int64) -> Int64:
    var a = left
    var b = right
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a
