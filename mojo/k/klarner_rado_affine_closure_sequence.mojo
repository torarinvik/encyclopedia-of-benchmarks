from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("klarner_rado_affine_closure_sequence")
fn klarner_rado_affine_closure_sequence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], input_length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < 1 or input_length > 2:
        return -1
    let requested = input[0]
    if input_length != 1 or requested < 1 or requested > 64:
        return -1

    var terms = InlineArray[Int64, 64](fill=0)
    terms[0] = 1
    var count = 1
    var twice = 0
    var thrice_plus_two = 0
    var sixfold_plus_three = 0
    while count < Int(requested):
        let by_two = 2 * terms[twice]
        let by_three = 3 * terms[thrice_plus_two] + 2
        let by_six = 6 * terms[sixfold_plus_three] + 3
        var next = by_two
        if by_three < next: next = by_three
        if by_six < next: next = by_six
        terms[count] = next
        count += 1
        if by_two == next: twice += 1
        if by_three == next: thrice_plus_two += 1
        if by_six == next: sixfold_plus_three += 1
    return terms[Int(requested) - 1]
