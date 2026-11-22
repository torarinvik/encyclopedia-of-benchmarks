from std.ffi import c_size_t
from std.memory import Pointer, stack_allocation

comptime MAX_STRING_LENGTH = 256
comptime MAX_PARSEABLE_INPUT_LENGTH = 259

@export("string_left_rotation")
def string_left_rotation(input_address: UInt64, length: c_size_t,
                         output_address: UInt64, capacity: c_size_t) abi("C") -> Int64:
    if input_address == 0 or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1

    var input = Pointer[Int64, UntrackedOrigin[mut=False]](
        unsafe_from_address=Int(input_address))
    var raw_length = input[unsafe_offset=0]
    var raw_rotation = input[unsafe_offset=1]
    if (raw_length < 0 or raw_length > MAX_STRING_LENGTH or raw_rotation < 0
        or raw_rotation > raw_length or length != c_size_t(raw_length + 2)):
        return -1
    var text_length = Int(raw_length)
    if text_length == 0:
        return 0

    var units = stack_allocation[MAX_STRING_LENGTH, UInt16]()
    var observed_bits = UInt64(0)
    for index in range(text_length):
        var value = UInt64(input[unsafe_offset=index + 2])
        observed_bits |= value
        units[unsafe_offset=index] = UInt16(value)
    if observed_bits > 65535:
        return -1

    var required = text_length * 2
    if output_address == 0 or capacity < c_size_t(required):
        return -2
    var output = Pointer[UInt8, UntrackedOrigin[mut=True]](
        unsafe_from_address=Int(output_address))
    var rotation = Int(raw_rotation)
    for source in range(rotation, text_length):
        var destination = 2 * (source - rotation)
        var value = units[unsafe_offset=source]
        output[unsafe_offset=destination] = UInt8(value)
        output[unsafe_offset=destination + 1] = UInt8(value >> 8)
    var suffix_bytes = 2 * (text_length - rotation)
    for source in range(rotation):
        var destination = suffix_bytes + 2 * source
        var value = units[unsafe_offset=source]
        output[unsafe_offset=destination] = UInt8(value)
        output[unsafe_offset=destination + 1] = UInt8(value >> 8)
    return Int64(required)
