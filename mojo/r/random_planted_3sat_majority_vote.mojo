from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("random_planted_3sat_majority_vote")
fn random_planted_3sat_majority_vote(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 98: return -1
    let variables = input[0]
    let clauses = input[1]
    if variables < 3 or variables > 12 or clauses < 0 or clauses > 32 or length != c_size_t(2 + 3 * clauses): return -1
    let n = Int(variables)
    var positive = InlineArray[Int64, 12](fill=0)
    var negative = InlineArray[Int64, 12](fill=0)
    for clause in range(Int(clauses)):
        var seen = InlineArray[Bool, 12](fill=False)
        for j in range(3):
            let literal = input[2 + 3 * clause + j]
            if literal == 0 or literal < -variables or literal > variables: return -1
            let variable = Int(abs(literal) - 1)
            if seen[variable]: return -1
            seen[variable] = True
            if literal > 0: positive[variable] += 1
            else: negative[variable] += 1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for variable in range(n):
        let choice: Int64 = if positive[variable] > negative[variable]: 1 else: -1
        var bits = bitcast[UInt64](choice)
        for byte in range(8):
            output[8 * variable + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
