from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("boyer_moore_majority_vote")
fn boyer_moore_majority_vote(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 256: return -1
    var candidate: Int64 = 0; var balance = 0
    for i in range(Int(length)):
        if balance == 0: candidate = input[i]
        if input[i] == candidate: balance += 1
        else: balance -= 1
    var count = 0
    for i in range(Int(length)):
        if input[i] == candidate: count += 1
    return candidate if count > Int(length) // 2 else -1
