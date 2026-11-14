from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("agrep_approx_substring_count")
fn agrep_approx_substring_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 4162: return -2
    let pv = input[0]
    let tv = input[1]
    let errors = input[2]
    if pv < 1 or pv > 63 or tv < 0 or tv > 4096 or errors < 0 or errors > 2: return -2
    let pattern_length = Int(pv)
    let text_length = Int(tv)
    if length != c_size_t(3+pattern_length+text_length): return -2
    for i in range(3, 3+pattern_length+text_length):
        if input[i] < 32 or input[i] > 126: return -2
    var previous = List[Int64](capacity=64)
    var current = List[Int64](capacity=64)
    for i in range(64):
        previous.append(Int64(i))
        current.append(0)
    var matches = Int64(0)
    for i in range(text_length):
        current[0] = 0
        for j in range(1, pattern_length+1):
            var substitution = previous[j-1]
            if input[3+j-1] != input[3+pattern_length+i]: substitution += 1
            current[j] = min(previous[j]+1, min(current[j-1]+1, substitution))
        if current[pattern_length] <= errors: matches += 1
        for j in range(pattern_length+1): previous[j] = current[j]
    return matches
