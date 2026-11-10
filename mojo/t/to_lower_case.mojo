from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin, MutUntrackedOrigin


@export("to_lower_case")
def to_lower_case(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]],
    length: c_size_t,
    output: Optional[Pointer[UInt8, MutUntrackedOrigin]],
    output_capacity: c_size_t,
) abi("C") -> Int64:
    if length == 0:
        return 0
    if length > 4096 or input == None:
        return -1
    var values = input.value()
    for index in range(Int(length)):
        var value = values[unsafe_offset=index]
        if value < 1 or value > 127:
            return -1
    if output_capacity < length or output == None:
        return -2
    var bytes = output.value()
    for index in range(Int(length)):
        var value = values[unsafe_offset=index]
        if value >= 65 and value <= 90:
            value += 32
        bytes[unsafe_offset=index] = UInt8(value)
    return Int64(length)
