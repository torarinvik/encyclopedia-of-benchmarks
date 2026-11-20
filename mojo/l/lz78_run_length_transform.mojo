from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn lz78rt_put(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & 255)

@export("lz78_run_length_transform")
fn lz78_run_length_transform(input: UnsafePointer[Int64, ImmutAnyOrigin],
    input_length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
    output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < 1 or input_length > 34: return -1
    if input[0] < 0 or input[0] > 32 or input_length != c_size_t(input[0] + 1): return -1
    let n = Int(input[0])
    for i in range(n):
        if input[i + 1] < 1 or input[i + 1] > 3: return -1

    var transformed = InlineArray[Int64, 32](fill=0)
    var transformed_length = 0
    var position = 0
    while position < n:
        let symbol = input[position + 1]
        var end = position + 1
        while end < n and input[end + 1] == symbol: end += 1
        let run_length = end - position
        var highest_bit = 0
        var value = run_length
        while value > 1:
            value = value >> 1
            highest_bit += 1
        var bit = highest_bit
        while bit >= 0:
            transformed[transformed_length] = if ((run_length >> bit) & 1) != 0: symbol else: 0
            transformed_length += 1
            bit -= 1
        position = end

    var children = InlineArray[Int64, 132](fill=0)
    var tokens = InlineArray[Int64, 96](fill=0)
    var token_count = 0
    var text_position = 0
    var next_phrase_id = 1
    while text_position < transformed_length:
        var node = 0
        var end = text_position
        while end < transformed_length:
            let child = Int(children[node * 4 + Int(transformed[end])])
            if child == 0: break
            node = child
            end += 1
        if end == transformed_length:
            if node != 0:
                tokens[token_count * 3] = Int64(node)
                tokens[token_count * 3 + 1] = 0
                tokens[token_count * 3 + 2] = 1
                token_count += 1
            break
        let symbol = Int(transformed[end])
        tokens[token_count * 3] = Int64(node)
        tokens[token_count * 3 + 1] = Int64(symbol)
        tokens[token_count * 3 + 2] = 0
        token_count += 1
        children[node * 4 + symbol] = Int64(next_phrase_id)
        next_phrase_id += 1
        text_position = end + 1

    let bytes = 8 + 24 * token_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(bytes): return -2
    lz78rt_put(output, 0, Int64(token_count))
    for token in range(token_count):
        for field in range(3):
            lz78rt_put(output, 8 + 24 * token + 8 * field, tokens[token * 3 + field])
    return Int64(bytes)
