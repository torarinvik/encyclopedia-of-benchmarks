from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_WORDS = 257
comptime MAX_PAYLOAD = 255
comptime MAX_OUTPUT = 257

@export("consistent_overhead_byte_stuffing")
fn consistent_overhead_byte_stuffing(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_WORDS:
        return -1
    let payload_value = input[0]
    if payload_value < 0 or payload_value > Int64(MAX_PAYLOAD): return -1
    let payload_length = Int(payload_value)
    if length != c_size_t(payload_length + 1): return -1
    for index in range(payload_length):
        if input[index + 1] < 0 or input[index + 1] > 255: return -1

    var staged = InlineArray[UInt8, MAX_OUTPUT](fill=0)
    var written = 1
    var code_position = 0
    var code: UInt16 = 1
    var omitted_terminal_code = False
    for index in range(payload_length):
        let byte = UInt8(input[index + 1])
        if byte == 0:
            staged[code_position] = UInt8(code)
            code_position = written
            written += 1
            code = 1
        else:
            staged[written] = byte
            written += 1
            code += 1
            if code == 255:
                staged[code_position] = 255
                if index + 1 == payload_length:
                    omitted_terminal_code = True
                    break
                code_position = written
                written += 1
                code = 1
    if not omitted_terminal_code: staged[code_position] = UInt8(code)

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(written): return -2
    for index in range(written): output[index] = staged[index]
    return Int64(written)
