# Independent bounded NBench-style heap sort; see package NBENCH-LICENSE.
from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin, MutUntrackedOrigin

def string_heap_sift[origin: MutOrigin](keys: Pointer[UInt32, origin], start: Int, end: Int):
    var root = start
    while root < end//2:
        var child = 2*root+1
        if child+1 < end and keys[unsafe_offset=child] < keys[unsafe_offset=child+1]: child += 1
        if keys[unsafe_offset=root] >= keys[unsafe_offset=child]: break
        var value = keys[unsafe_offset=root]
        keys[unsafe_offset=root] = keys[unsafe_offset=child]
        keys[unsafe_offset=child] = value
        root = child

@export("string_heap_sort")
def string_heap_sort(input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t,
        output: Optional[Pointer[UInt8, MutUntrackedOrigin]], capacity: c_size_t) abi("C") -> Int64:
    if input == None or length < 1 or length > 257:
        return -1
    var values = input.value()
    var count = Int(values[unsafe_offset=0])
    if count < 0 or count > 64 or Int(length) != 1 + 4 * count:
        return -1
    var storage = Array[UInt32, 64](fill=0)
    var keys = storage.unsafe_ptr()
    for index in range(count):
        var key = UInt32(0)
        for byte_index in range(4):
            var byte = values[unsafe_offset=1 + 4 * index + byte_index]
            if byte < 0 or byte > 127:
                return -1
            key = (key << 8) | UInt32(byte)
        keys[unsafe_offset=index] = key
    for index in range(count // 2):
        string_heap_sift(keys, count // 2 - 1 - index, count)
    for index in range(1, count):
        var end = count - index
        var root = keys[unsafe_offset=0]
        keys[unsafe_offset=0] = keys[unsafe_offset=end]
        keys[unsafe_offset=end] = root
        string_heap_sift(keys, 0, end)
    var byte_count = 4 * count
    if output == None or capacity < c_size_t(byte_count):
        return -2
    var result = output.value()
    for index in range(count):
        for byte_index in range(4):
            result[unsafe_offset=4 * index + byte_index] = UInt8((keys[unsafe_offset=index] >> UInt32(24 - 8 * byte_index)) & 255)
    return Int64(byte_count)
