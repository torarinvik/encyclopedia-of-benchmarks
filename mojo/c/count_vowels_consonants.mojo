from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_vowels_consonants")
fn count_vowels_consonants(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 100000 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var vowels: Int64 = 0
    var consonants: Int64 = 0
    for i in range(length):
        let code = values[i]
        if code < 0 or code > 127: return -1
        if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
            let c = code | 32
            if c == 97 or c == 101 or c == 105 or c == 111 or c == 117: vowels += 1
            else: consonants += 1
    return vowels * 4294967296 + consonants
