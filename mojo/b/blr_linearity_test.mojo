from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("blr_linearity_test")
fn blr_linearity_test(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                      output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let n64 = input[0]
    let q64 = input[1]
    if n64 < 1 or n64 > 6 or q64 < 1 or q64 > 32: return -1
    let n = Int(n64)
    let q = Int(q64)
    let domain = 1 << n
    if length != c_size_t(2 + domain + 2*q): return -1
    let table_at = 2
    let tape_at = table_at + domain
    for i in range(domain):
        if input[table_at+i] != 0 and input[table_at+i] != 1: return -1
    for i in range(2*q):
        let point = input[tape_at+i]
        if point < 0 or point >= Int64(domain): return -1
    var rounds = 0
    var accepted: Int64 = 1
    for round in range(q):
        let x = Int(input[tape_at+2*round])
        let y = Int(input[tape_at+2*round+1])
        rounds += 1
        if (input[table_at+x] ^ input[table_at+y]) != input[table_at+(x ^ y)]:
            accepted = 0
            break
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24: return -2
    put_word(output, 0, accepted)
    put_word(output, 8, Int64(rounds))
    put_word(output, 16, Int64(3*rounds))
    return 24
