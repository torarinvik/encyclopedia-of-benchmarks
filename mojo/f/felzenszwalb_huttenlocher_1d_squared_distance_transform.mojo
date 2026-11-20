from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn floor_div(numerator: Int64, denominator: Int64) -> Int64:
    if numerator < 0:
        return -((-numerator) // denominator)
    return numerator // denominator

@export("felzenszwalb_huttenlocher_1d_squared_distance_transform")
fn felzenszwalb_huttenlocher_1d_squared_distance_transform(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130:
        return -1
    let n64 = input[0]
    if n64 < 1 or n64 > 128:
        return -1
    let n = Int(n64)
    if length != c_size_t(n + 1):
        return -1
    for i in range(n):
        let cost = input[i + 1]
        if cost < 0 or cost > 1_000_000:
            return -1
    let output_bytes = n * 16
    if (output == UnsafePointer[UInt8, MutAnyOrigin]()
        or output_capacity < c_size_t(output_bytes)):
        return -2

    var sites = InlineArray[Int, 128](fill=0)
    var starts = InlineArray[Int64, 128](fill=0)
    var top = 0
    sites[0] = 0
    starts[0] = -4_611_686_018_427_387_904
    for q in range(1, n):
        while True:
            let p = sites[top]
            let numerator = input[q + 1] + Int64(q * q)
                - input[p + 1] - Int64(p * p)
            let denominator = Int64(2 * (q - p))
            let first = floor_div(numerator, denominator) + 1
            if top == 0 or first > starts[top]:
                top += 1
                sites[top] = q
                starts[top] = first
                break
            top -= 1

    var active = 0
    for x in range(n):
        while active < top and starts[active + 1] <= Int64(x):
            active += 1
        let site = sites[active]
        let delta = Int64(x - site)
        let distance = delta * delta + input[site + 1]
        let distance_bits = UInt64(distance)
        let site_bits = UInt64(site)
        for byte in range(8):
            output[x * 16 + byte] = UInt8((distance_bits >> (byte * 8)) & 255)
            output[x * 16 + 8 + byte] = UInt8((site_bits >> (byte * 8)) & 255)
    return Int64(output_bytes)
