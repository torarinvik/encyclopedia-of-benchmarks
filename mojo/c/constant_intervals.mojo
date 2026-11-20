from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ci_value(index: Int, step: Int64, offset: Int64, divisor: Int64) -> Int32:
    return Int32((step * Int64(index) + offset) // divisor)

fn ci_store(output: UnsafePointer[UInt8, MutAnyOrigin], position: Int, value: Int32):
    let bits = UInt32(value)
    for byte in range(4):
        output[position + byte] = UInt8((bits >> (8 * byte)) & 255)

fn ci_append(lo: Int, hi: Int, value: Int32,
             output: UnsafePointer[UInt8, MutAnyOrigin],
             inout count: Int, inout last_hi: Int, inout last_value: Int32,
             inout has_last: Bool):
    if has_last and last_hi == lo and last_value == value:
        ci_store(output, (count - 1) * 12 + 4, Int32(hi))
    else:
        let position = count * 12
        ci_store(output, position, Int32(lo))
        ci_store(output, position + 4, Int32(hi))
        ci_store(output, position + 8, value)
        count += 1
    last_hi = hi
    last_value = value
    has_last = True

fn ci_visit(lo: Int, hi: Int, step: Int64, offset: Int64, divisor: Int64,
            output: UnsafePointer[UInt8, MutAnyOrigin],
            inout count: Int, inout last_hi: Int, inout last_value: Int32,
            inout has_last: Bool):
    let first = ci_value(lo, step, offset, divisor)
    let last = ci_value(hi - 1, step, offset, divisor)
    if first == last or hi - lo == 1:
        ci_append(lo, hi, first, output, count, last_hi, last_value, has_last)
        return
    let mid = lo + (hi - lo) // 2
    ci_visit(lo, mid, step, offset, divisor, output, count, last_hi, last_value, has_last)
    ci_visit(mid, hi, step, offset, divisor, output, count, last_hi, last_value, has_last)

@export("constant_intervals")
fn constant_intervals(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1
    let n_value = input[0]
    let step = input[1]
    let offset = input[2]
    let divisor = input[3]
    if n_value < 0 or n_value > 256 or step < 0 or step > 65535
        or offset < 0 or offset > 65535 or divisor < 1 or divisor > 65535: return -1
    let n = Int(n_value)
    let maximum_bytes = n * 12
    if output_capacity < c_size_t(maximum_bytes)
        or (maximum_bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    if n == 0: return 0
    var count = 0
    var last_hi = 0
    var last_value = Int32(0)
    var has_last = False
    ci_visit(0, n, step, offset, divisor, output, count, last_hi, last_value, has_last)
    return Int64(count)
