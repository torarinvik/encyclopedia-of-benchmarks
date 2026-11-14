from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

fn mismatch_count(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int, size: Int, period: Int) -> Int:
    var result = 0
    for offset in range(size-period):
        if input[2+start+offset] != input[2+start+offset+period]: result += 1
    return result

@export("approximate_tandem_k_repetitions")
fn approximate_tandem_k_repetitions(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 26: return -1
    let nv = input[0]
    let kv = input[1]
    if nv < 3 or nv > 24 or kv < 0 or kv > 8: return -1
    let n = Int(nv)
    let budget = Int(kv)
    if length != c_size_t(2+n): return -1
    for i in range(n):
        if input[2+i] < 0 or input[2+i] > 3: return -1
    var count = 0
    for start in range(n):
        let remaining = n-start
        for period in range(1, (remaining+1)//2):
            for size in range(2*period+1, remaining+1):
                if mismatch_count(input, start, size, period) <= budget: count += 1
    let bytes = 8*(1+4*count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    put_word(output, 0, Int64(count))
    var record = 0
    for start in range(n):
        let remaining = n-start
        for period in range(1, (remaining+1)//2):
            for size in range(2*period+1, remaining+1):
                let errors = mismatch_count(input, start, size, period)
                if errors <= budget:
                    let offset = 8*(1+4*record)
                    put_word(output, offset, Int64(start))
                    put_word(output, offset+8, Int64(size))
                    put_word(output, offset+16, Int64(period))
                    put_word(output, offset+24, Int64(errors))
                    record += 1
    return Int64(bytes)
