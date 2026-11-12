from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime ML_N = 24
comptime ML_MAX_REPETITIONS = ML_N * ML_N // 4
comptime ML_INPUT_MAX = ML_N + 1
comptime ML_Z_MAX = 2 * ML_N + 1
comptime ML_MARK_SIZE = ML_N * (ML_N + 1)

fn ml_z_values(text: InlineArray[Int64, ML_Z_MAX], length: Int,
    inout z: InlineArray[Int, ML_Z_MAX]):
    for i in range(ML_Z_MAX): z[i] = 0
    var left = 0
    var right = 0
    var has_box = False
    for i in range(1, length):
        if has_box and i <= right: z[i] = min(right - i + 1, z[i - left])
        while i + z[i] < length and text[z[i]] == text[i + z[i]]: z[i] += 1
        if not has_box or i + z[i] - 1 > right:
            left = i
            right = i + z[i] - 1
            has_box = True

fn ml_z_at(z: InlineArray[Int, ML_Z_MAX], length: Int, index: Int) -> Int:
    if index < length: return z[index]
    return 0

fn ml_divide(symbols: InlineArray[Int64, ML_N], offset: Int, length: Int,
    inout marked: InlineArray[Bool, ML_MARK_SIZE]):
    if length <= 1: return
    let left_size = length // 2
    let right_size = length - left_size
    let middle = offset + left_size
    var buffer = InlineArray[Int64, ML_Z_MAX](fill=0)
    var z = InlineArray[Int, ML_Z_MAX](fill=0)
    var before = InlineArray[Int, ML_N](fill=0)
    var after = InlineArray[Int, ML_N](fill=0)

    ml_divide(symbols, offset, left_size, marked)
    ml_divide(symbols, middle, right_size, marked)

    for i in range(left_size): buffer[i] = symbols[middle - 1 - i]
    ml_z_values(buffer, left_size, z)
    for center in range(left_size): before[center] = ml_z_at(z, left_size, left_size - center)

    var used = 0
    for i in range(right_size):
        buffer[used] = symbols[middle + i]
        used += 1
    buffer[used] = -1
    used += 1
    for i in range(left_size):
        buffer[used] = symbols[offset + i]
        used += 1
    ml_z_values(buffer, used, z)
    for center in range(left_size): after[center] = ml_z_at(z, used, right_size + 1 + center)

    for i in range(left_size): buffer[i] = symbols[middle - 1 - i]
    used = left_size
    buffer[used] = -1
    used += 1
    for i in range(right_size):
        buffer[used] = symbols[offset + length - 1 - i]
        used += 1
    ml_z_values(buffer, used, z)
    for d in range(right_size):
        before[left_size + d] = ml_z_at(z, used, left_size + 1 + right_size - 1 - d)

    for i in range(right_size): buffer[i] = symbols[middle + i]
    ml_z_values(buffer, right_size, z)
    for d in range(right_size): after[left_size + d] = ml_z_at(z, right_size, d + 1)

    for center in range(length):
        let left_biased = center < left_size
        let half = left_size - center if left_biased else center - left_size + 1
        if before[center] + after[center] < half: continue
        let low = max(1, half - after[center])
        let high = min(half, before[center])
        for first_half in range(low, high + 1):
            if left_biased and first_half == half: continue
            let start = center - first_half if left_biased else center - half - first_half + 1
            marked[(offset + start) * (ML_N + 1) + half] = True

fn ml_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("main_lorentz_tandem_repetitions")
fn main_lorentz_tandem_repetitions(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > ML_INPUT_MAX:
        return -1
    let nr = input[0]
    if nr < 0 or nr > ML_N or Int(length) != Int(nr) + 1: return -1
    let n = Int(nr)
    var symbols = InlineArray[Int64, ML_N](fill=0)
    for i in range(n):
        symbols[i] = input[i + 1]
        if symbols[i] < 0 or symbols[i] > 255: return -1
    var marked = InlineArray[Bool, ML_MARK_SIZE](fill=False)
    ml_divide(symbols, 0, n, marked)
    var codes = InlineArray[Int64, ML_MAX_REPETITIONS](fill=0)
    var count = 0
    for start in range(n):
        for half in range(1, n // 2 + 1):
            if start + 2 * half <= n and marked[start * (ML_N + 1) + half]:
                codes[count] = Int64(start * 32 + half)
                count += 1
    let required = 8 * (count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    ml_store(output, 0, Int64(count))
    for i in range(count): ml_store(output, 8 * (i + 1), codes[i])
    return Int64(required)
