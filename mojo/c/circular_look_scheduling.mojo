from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("circular_look_scheduling")
fn circular_look_scheduling(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 68: return -1
    let max_cylinder = values[0]
    let start = values[1]
    let moving_up = values[2]
    let request_count = values[3]
    if max_cylinder < 1 or max_cylinder > 128 or start < 0 or start >= max_cylinder or (moving_up != 0 and moving_up != 1) or request_count < 0 or request_count > 64 or length != 4 + request_count: return -1
    var up = InlineArray[Int64, 64](0)
    var down = InlineArray[Int64, 64](0)
    var up_count: Int64 = 0
    var down_count: Int64 = 0
    for i in range(request_count):
        let request = values[4 + i]
        if request < -128 or request > 255: return -1
        if request < 0 or request >= max_cylinder or request == start: continue
        if request > start:
            var pos = up_count
            while pos > 0 and up[pos - 1] > request:
                up[pos] = up[pos - 1]
                pos -= 1
            up[pos] = request
            up_count += 1
        else:
            var pos = down_count
            while pos > 0 and down[pos - 1] > request:
                down[pos] = down[pos - 1]
                pos -= 1
            down[pos] = request
            down_count += 1
    let output_count = up_count + down_count
    if capacity < output_count or (output_count > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var staged = InlineArray[UInt8, 64](0)
    var pos: Int64 = 0
    if moving_up == 1:
        for i in range(up_count):
            staged[pos] = UInt8(up[i])
            pos += 1
        for i in range(down_count):
            staged[pos] = UInt8(down[i])
            pos += 1
    else:
        var i = down_count
        while i > 0:
            i -= 1
            staged[pos] = UInt8(down[i])
            pos += 1
        i = up_count
        while i > 0:
            i -= 1
            staged[pos] = UInt8(up[i])
            pos += 1
    for i in range(output_count): output[i] = staged[i]
    return output_count
