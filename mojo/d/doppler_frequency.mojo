from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("doppler_frequency")
fn doppler_frequency(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -1.0e300
    let org=input[0];let wave=input[1];let obs=input[2];let src=input[3]
    if org<1 or org>1000 or wave<200 or wave>1000 or obs< -100 or obs>100 or src< -100 or src>100:return -1.0e300
    return (Float64(org)*(Float64(wave)+Float64(obs)))/(Float64(wave)-Float64(src))
