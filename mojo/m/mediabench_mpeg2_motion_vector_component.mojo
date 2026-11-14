from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("mediabench_mpeg2_motion_vector_component")
fn mediabench_mpeg2_motion_vector_component(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4:
        return -1
    let predictor = input[0]
    let size = input[1]
    let code = input[2]
    let residual = input[3]
    if size < 0 or size > 6 or code < -16 or code > 16:
        return -1
    let shift = Int(size)
    let limit = Int64(16) << shift
    if predictor < -limit or predictor >= limit:
        return -1
    if code == 0 or size == 0:
        if residual != 0:
            return -1
    elif residual < 0 or residual >= (Int64(1) << shift):
        return -1
    var result = predictor
    if code > 0:
        result += ((code - 1) << shift) + residual + 1
        if result >= limit:
            result -= 2 * limit
    elif code < 0:
        result -= ((-code - 1) << shift) + residual + 1
        if result < -limit:
            result += 2 * limit
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
        return -2
    var bits = bitcast[UInt64](result)
    for byte in range(8):
        output[byte] = UInt8(bits & 255)
        bits >>= 8
    return 8
