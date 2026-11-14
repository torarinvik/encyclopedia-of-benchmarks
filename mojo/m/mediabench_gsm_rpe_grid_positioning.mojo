# Independent GSM grid positioning. The upstream notice is retained in
# benchmarks/m/mediabench_gsm_rpe_grid_positioning/COPYRIGHT.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("mediabench_gsm_rpe_grid_positioning")
fn mediabench_gsm_rpe_grid_positioning(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 14:
        return -1
    let grid = input[0]
    if grid < 0 or grid > 3:
        return -1
    var samples = InlineArray[Int64, 40](fill=0)
    for i in range(13):
        let sample = input[i + 1]
        if sample < -32768 or sample > 32767:
            return -1
        samples[Int(grid) + 3 * i] = sample
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 80:
        return -2
    for i in range(40):
        let bits = bitcast[UInt64](samples[i])
        output[2 * i] = UInt8(bits & 255)
        output[2 * i + 1] = UInt8((bits >> 8) & 255)
    return 80
