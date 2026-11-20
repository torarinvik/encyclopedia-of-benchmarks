from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_LIMIT = 61
comptime MAX_TRIPLES = 69
comptime MAX_OUTPUT_BYTES = 832

fn tpc_is_prime(value: Int64) -> Bool:
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    var divisor: Int64 = 3
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 2
    return True

fn tpc_put_u32(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: UInt32):
    for byte in range(4):
        output[offset + byte] = UInt8((value >> UInt(byte * 8)) & UInt32(255))

@export("three_prime_carmichael_enumerator")
fn three_prime_carmichael_enumerator(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != c_size_t(1):
        return -1
    let limit = input[0]
    if limit < 2 or limit > MAX_LIMIT:
        return -1

    var triples = InlineArray[UInt32, MAX_TRIPLES * 3]()
    var triple_count = 0
    for p1 in range(2, Int(limit) + 1):
        let p1_64 = Int64(p1)
        if not tpc_is_prime(p1_64):
            continue
        for h3 in range(2, p1):
            let h3_64 = Int64(h3)
            let g = h3_64 + p1_64
            for d in range(1, Int(g)):
                let d64 = Int64(d)
                if (g * (p1_64 - 1)) % d64 != 0:
                    continue
                let negative_square_residue = (h3_64 - (p1_64 * p1_64) % h3_64) % h3_64
                if negative_square_residue != d64 % h3_64:
                    continue
                let p2 = 1 + (p1_64 - 1) * g // d64
                if p2 <= p1_64 or not tpc_is_prime(p2):
                    continue
                let p3 = 1 + (p1_64 * p2) // h3_64
                if p3 <= p2 or not tpc_is_prime(p3):
                    continue
                if (p2 * p3) % (p1_64 - 1) != 1:
                    continue
                triples[triple_count * 3] = UInt32(p1_64)
                triples[triple_count * 3 + 1] = UInt32(p2)
                triples[triple_count * 3 + 2] = UInt32(p3)
                triple_count += 1

    let required = 4 + triple_count * 12
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    tpc_put_u32(output, 0, UInt32(triple_count))
    for record in range(triple_count):
        tpc_put_u32(output, 4 + record * 12, triples[record * 3])
        tpc_put_u32(output, 8 + record * 12, triples[record * 3 + 1])
        tpc_put_u32(output, 12 + record * 12, triples[record * 3 + 2])
    return Int64(required)
