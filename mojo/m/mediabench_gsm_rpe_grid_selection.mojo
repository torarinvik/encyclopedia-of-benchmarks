# Independent GSM grid selection. The upstream notice is retained in
# benchmarks/m/mediabench_gsm_rpe_grid_selection/COPYRIGHT.txt.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("mediabench_gsm_rpe_grid_selection")
fn mediabench_gsm_rpe_grid_selection(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 40:
        return -1
    var samples = InlineArray[Int64, 40](fill=0)
    for i in range(40):
        let value = input[i]
        if value < -32768 or value > 32767:
            return -1
        samples[i] = value
    var best_score: Int64 = -1
    var best_grid = 0
    for grid in range(4):
        var score: Int64 = 0
        for i in range(13):
            let value = samples[grid + 3 * i]
            let scaled = if value >= 0: value // 4 else: -((-value + 3) // 4)
            score += 2 * scaled * scaled
        if score > best_score:
            best_score = score
            best_grid = grid
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 112:
        return -2
    for slot in range(14):
        let value = if slot == 0: Int64(best_grid) else: samples[best_grid + 3 * (slot - 1)]
        var bits = bitcast[UInt64](value)
        for byte in range(8):
            output[8 * slot + byte] = UInt8(bits & 255)
            bits >>= 8
    return 112
