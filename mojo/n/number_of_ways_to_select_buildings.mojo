from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("number_of_ways_to_select_buildings")
def number_of_ways_to_select_buildings(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if length == 0:
        return 0
    if input == None or length > 4096:
        return -1
    var values = input.value()
    var different_bits: UInt64 = 0
    var ways: UInt64 = 0
    var zeros: UInt32 = 0
    var ones: UInt32 = 0
    var zero_one: UInt32 = 0
    var one_zero: UInt32 = 0
    for index in range(Int(length)):
        var value = UInt64(values[unsafe_offset=index]) ^ 48
        different_bits |= value
        var is_one = (value & 1) != 0
        ways += UInt64(one_zero if is_one else zero_one)
        zero_one += zeros if is_one else 0
        one_zero += 0 if is_one else ones
        zeros += UInt32(0 if is_one else 1)
        ones += UInt32(1 if is_one else 0)
    if different_bits > 1:
        return -1
    return Int64(ways)
