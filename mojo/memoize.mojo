from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_CALLS = 64
comptime MAX_INPUT_LENGTH = 259


fn write_i64_le(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))


@export("memoize")
fn memoize(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let arity = input[0]
    let call_count = input[1]
    if arity < 0 or arity > 4 or call_count < 0 or call_count > MAX_CALLS:
        return -1
    if Int(length) != 2 + Int(arity * call_count):
        return -1
    for argument_index in range(Int(arity * call_count)):
        let value = input[2 + argument_index]
        if value < -100 or value > 100:
            return -1

    let required = 8 * (Int(call_count) + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    var keys = InlineArray[Int64, MAX_CALLS](fill=0)
    var key_arities = InlineArray[Int64, MAX_CALLS](fill=0)
    var results = InlineArray[Int64, MAX_CALLS](fill=0)
    var output_values = InlineArray[Int64, MAX_CALLS](fill=0)
    var cache_size = 0
    var evaluations = 0
    for call_index in range(Int(call_count)):
        var key: Int64 = 0
        for arg_index in range(Int(arity)):
            let argument = input[2 + call_index * Int(arity) + arg_index]
            key = key * 201 + (argument + 100)
        var cached_at = -1
        for cache_index in range(cache_size):
            if key_arities[cache_index] == arity and keys[cache_index] == key:
                cached_at = cache_index
                break
        if cached_at >= 0:
            output_values[call_index] = results[cached_at]
        else:
            keys[cache_size] = key
            key_arities[cache_size] = arity
            results[cache_size] = key
            output_values[call_index] = key
            cache_size += 1
            evaluations += 1

    for call_index in range(Int(call_count)):
        write_i64_le(output, call_index * 8, output_values[call_index])
    write_i64_le(output, Int(call_count) * 8, Int64(evaluations))
    return Int64(required)
