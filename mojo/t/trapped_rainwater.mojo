from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


def trapped_water_with_suffix[capacity: Int](
    heights: Pointer[Int64, ImmUntrackedOrigin], count: Int
) -> Int64:
    var storage = Array[UInt32, capacity](fill=0)
    var suffix = storage.unsafe_ptr()
    var boundary: UInt32 = 0
    for step in range(count):
        var index = count - 1 - step
        var raw = UInt64(heights[unsafe_offset=index])
        if raw > 1_000_000:
            return -1
        boundary = max(boundary, UInt32(raw))
        suffix[unsafe_offset=index] = boundary

    var water: UInt32 = 0
    boundary = 0
    for index in range(count):
        var height = UInt32(heights[unsafe_offset=index])
        boundary = max(boundary, height)
        water += min(boundary, suffix[unsafe_offset=index]) - height
    return Int64(water)


@export("trapped_rainwater")
def trapped_rainwater(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if length == 0:
        return 0
    if length > 4096 or input == None:
        return -1
    var heights = input.value()
    var count = Int(length)
    if count <= 16:
        return trapped_water_with_suffix[16](heights, count)
    return trapped_water_with_suffix[4096](heights, count)
