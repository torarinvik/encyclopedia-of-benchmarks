from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_OPERATIONS = 64
comptime MAX_INSERTIONS = 16
comptime MAX_INPUT_VALUES = 129
comptime BIT_COUNT = 63

fn xor_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("xor_linear_basis")
fn xor_linear_basis(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_VALUES):
        return -1
    let q_value = input[0]
    if q_value < 1 or q_value > MAX_OPERATIONS:
        return -1
    let q = Int(q_value)

    var basis = InlineArray[UInt64, BIT_COUNT](fill=0)
    var results = InlineArray[Int64, MAX_OPERATIONS](fill=0)
    var result_count = 0
    var cursor = 1
    var insertion_count = 0
    for _ in range(q):
        if cursor >= Int(length):
            return -1
        let kind = input[cursor]
        cursor += 1
        if kind == 0 or kind == 2:
            if cursor >= Int(length):
                return -1
            let raw_value = input[cursor]
            cursor += 1
            if raw_value < 0:
                return -1
            var value = UInt64(raw_value)
            if kind == 0:
                insertion_count += 1
                if insertion_count > MAX_INSERTIONS:
                    return -1
                for offset in range(BIT_COUNT):
                    let bit = BIT_COUNT - 1 - offset
                    if value == 0:
                        break
                    if ((value >> bit) & 1) == 0:
                        continue
                    if basis[bit] == 0:
                        basis[bit] = value
                        break
                    value ^= basis[bit]
            else:
                var possible: Bool = true
                var reduced = value
                for offset in range(BIT_COUNT):
                    let bit = BIT_COUNT - 1 - offset
                    if ((reduced >> bit) & 1) == 0:
                        continue
                    if basis[bit] == 0:
                        possible = False
                        break
                    reduced ^= basis[bit]
                results[result_count] = 1 if possible and reduced == 0 else 0
                result_count += 1
        elif kind == 1:
            var best: UInt64 = 0
            for offset in range(BIT_COUNT):
                let bit = BIT_COUNT - 1 - offset
                let candidate = best ^ basis[bit]
                if candidate > best:
                    best = candidate
            results[result_count] = Int64(best)
            result_count += 1
        else:
            return -1
    if cursor != Int(length):
        return -1

    let output_bytes = result_count * 8
    if output_bytes == 0:
        return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for result in range(result_count):
        xor_store(output, 8 * result, results[result])
    return Int64(output_bytes)
