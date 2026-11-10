from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("trapped_rainwater_two_pointer")
def trapped_rainwater_two_pointer(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if length == 0:
        return 0
    if length > 4096 or input == None:
        return -1

    var heights = input.value()
    var left = 0
    var right = Int(length) - 1
    var left_height = UInt64(heights[unsafe_offset=left])
    var right_height = UInt64(heights[unsafe_offset=right])
    if left_height > 1_000_000 or right_height > 1_000_000:
        return -1

    var left_max: UInt32 = 0
    var right_max: UInt32 = 0
    var trapped: UInt32 = 0
    while left < right:
        if left_height < right_height:
            var height = UInt32(left_height)
            left_max = max(left_max, height)
            trapped += left_max - height
            left += 1
            left_height = UInt64(heights[unsafe_offset=left])
            if left_height > 1_000_000:
                return -1
        else:
            var height = UInt32(right_height)
            right_max = max(right_max, height)
            trapped += right_max - height
            right -= 1
            right_height = UInt64(heights[unsafe_offset=right])
            if right_height > 1_000_000:
                return -1
    return Int64(trapped)
