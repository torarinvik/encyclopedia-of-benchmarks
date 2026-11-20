from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_TERMS = 16
const MAX_LENGTH = 34
const MAX_MANTISSA = Int64(16777216)
const OUTPUT_SCALE = Float64(1073741824.0)

fn ses_two_sum(a: Float64, b: Float64) -> (Float64, Float64):
    let rounded = a+b
    let b_virtual = rounded-a
    let a_virtual = rounded-b_virtual
    let b_roundoff = b-b_virtual
    let a_roundoff = a-a_virtual
    return (rounded,a_roundoff+b_roundoff)

fn ses_grow_expansion(expansion: InlineArray[Float64,MAX_TERMS+1], count: Int,
                      value: Float64, inout grown: InlineArray[Float64,MAX_TERMS+1]) -> Int:
    var q=value
    var grown_count=0
    for i in range(count):
        let (high,low)=ses_two_sum(q,expansion[i])
        if low!=0.0:
            grown[grown_count]=low
            grown_count+=1
        q=high
    if q!=0.0 or grown_count==0:
        grown[grown_count]=q
        grown_count+=1
    return grown_count

@export("shewchuk_expansion_sum")
fn shewchuk_expansion_sum(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>MAX_LENGTH: return -1
    if input[0]<0 or input[0]>Int64(MAX_TERMS): return -1
    let n=Int(input[0])
    if length!=c_size_t(1+2*n): return -1

    var expansion=InlineArray[Float64,MAX_TERMS+1](fill=0.0)
    var grown=InlineArray[Float64,MAX_TERMS+1](fill=0.0)
    var expansion_count=0
    for i in range(n):
        let mantissa=input[1+2*i]
        let exponent=input[2+2*i]
        if mantissa < -MAX_MANTISSA or mantissa > MAX_MANTISSA or exponent < -30 or exponent > 0: return -1
        var value=Float64(mantissa)
        var shift=0
        while shift>Int(exponent):
            value*=0.5
            shift-=1
        if value!=0.0:
            let grown_count=ses_grow_expansion(expansion,expansion_count,value,grown)
            for j in range(grown_count): expansion[j]=grown[j]
            expansion_count=grown_count
    var result:Int64=Int64(288230376151711745)
    for i in range(expansion_count):
        result+=Int64(expansion[i]*OUTPUT_SCALE)
    return result
