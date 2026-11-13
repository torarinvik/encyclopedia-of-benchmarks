from std.ffi import c_size_t
from std.math import cos, exp, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_INPUT_LENGTH = 5

fn exact_integer(value: Float64, low: Int, high: Int) -> Bool:
    if not isfinite(value) or value < Float64(low) or value > Float64(high): return False
    return Float64(Int(value)) == value

fn integrand(id: Int, x: Float64) -> Float64:
    if id == 0: return exp(x)
    if id == 1: return x*x*x*x*x
    if id == 2: return 1.0/(1.0+x*x)
    return cos(x)

fn romberg(id: Int, a: Float64, b: Float64, levels: Int) -> Float64:
    if a == b: return 0.0
    var previous = InlineArray[Float64, 9](fill=0.0)
    previous[0] = (b-a)*(integrand(id,a)+integrand(id,b))*0.5
    for level in range(1,levels+1):
        let interval_count = 1 << level
        let spacing = (b-a)/Float64(interval_count)
        var added = 0.0
        for index in range(1,interval_count,2):
            added += integrand(id,a+Float64(index)*spacing)
        var current = InlineArray[Float64, 9](fill=0.0)
        current[0] = previous[0]*0.5+spacing*added
        var factor = 4.0
        for order in range(1,level+1):
            current[order]=current[order-1]+(current[order-1]-previous[order-1])/(factor-1.0)
            factor *= 4.0
        previous = current
    return previous[levels]

@export("romberg_integration")
fn romberg_integration(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length != 4 or input_length > MAX_INPUT_LENGTH: return -1
    let raw_id=input[0]; let raw_a=input[1]; let raw_b=input[2]; let raw_levels=input[3]
    if not exact_integer(raw_id,0,3) or not exact_integer(raw_a,-1000000,1000000) or not exact_integer(raw_b,-1000000,1000000) or not exact_integer(raw_levels,3,8): return -1
    let id=Int(raw_id); let a_micro=Int(raw_a); let b_micro=Int(raw_b); let levels=Int(raw_levels)
    if a_micro>b_micro: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 1: return -2
    let result=romberg(id,Float64(a_micro)/1000000.0,Float64(b_micro)/1000000.0,levels)
    if not isfinite(result): return -1
    output[0]=result
    return 1
