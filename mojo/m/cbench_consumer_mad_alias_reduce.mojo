# Independent bounded alias-reduction profile; see package LICENSE.txt.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn alias_floor(value: Int64, divisor: Int64) -> Int64:
    if value >= 0: return value // divisor
    return -((-value + divisor - 1) // divisor)

fn alias_mul(a: Int64, b: Int64) -> Int64:
    return alias_floor(a + 2048, 4096) * alias_floor(b + 32768, 65536)

@export("cbench_consumer_mad_alias_reduce")
fn cbench_consumer_mad_alias_reduce(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 17 or length > 65: return -1
    let boundaries = input[0]
    if boundaries < 1 or boundaries > 4 or length != c_size_t(1 + 16 * boundaries): return -1
    var samples = InlineArray[Int64, 64](fill=0)
    for i in range(16 * Int(boundaries)):
        let value = input[i + 1]
        if value < -100000000 or value > 100000000: return -1
        samples[i] = value
    let bytes = 64 * Int(boundaries)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var cs = InlineArray[Int64, 8](fill=0)
    cs[0]=0x0db84a81; cs[1]=0x0e1b9d7f; cs[2]=0x0f31adcf; cs[3]=0x0fbba815
    cs[4]=0x0feda417; cs[5]=0x0ffc8fc8; cs[6]=0x0fff964c; cs[7]=0x0ffff8d3
    var ca = InlineArray[Int64, 8](fill=0)
    ca[0] = -0x083b5fe7; ca[1] = -0x078c36d2; ca[2] = -0x05039814; ca[3] = -0x02e91dd1
    ca[4] = -0x0183603a; ca[5] = -0x00a7cb87; ca[6] = -0x003a2847; ca[7] = -0x000f27b4
    for boundary in range(Int(boundaries)):
        for i in range(8):
            let a = samples[16 * boundary + 2 * i]
            let b = samples[16 * boundary + 2 * i + 1]
            let left = alias_mul(a, cs[i]) + alias_mul(-b, ca[i])
            let right = alias_mul(b, cs[i]) + alias_mul(a, ca[i])
            let left_bits = bitcast[UInt64](left)
            let right_bits = bitcast[UInt64](right)
            let at = 64 * boundary + 8 * i
            for byte in range(4):
                output[at + byte] = UInt8((left_bits >> (8 * byte)) & 255)
                output[at + 4 + byte] = UInt8((right_bits >> (8 * byte)) & 255)
    return Int64(bytes)
