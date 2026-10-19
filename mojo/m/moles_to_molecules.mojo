from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("moles_to_molecules")
fn moles_to_molecules(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<0 or v[0]>2000000:return -1.0e300
    let x=(Float64(v[0])/1000000.0)*6.022e23
    if x==0.0:return 0.0
    var exponent=0;var normalized=x
    while normalized>=10.0:normalized/=10.0;exponent+=1
    while normalized<1.0:normalized*=10.0;exponent-=1
    let scaled=normalized*10000.0;var mantissa=Int64(scaled)
    let fraction=scaled-Float64(mantissa)
    if fraction>0.5 or (fraction==0.5 and mantissa%2==1):mantissa+=1
    if mantissa==100000:mantissa=10000;exponent+=1
    var factor=1.0
    for _ in range(abs(exponent-4)):factor*=10.0
    return Float64(mantissa)*factor if exponent>=4 else Float64(mantissa)/factor
