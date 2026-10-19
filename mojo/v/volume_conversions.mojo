from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("volume_conversions")
fn volume_conversions(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let value=v[0];let from=v[1];let to=v[2]
    if value<0 or value>1000 or from<0 or from>2 or to<0 or to>2 or from==to:return -1
    let sf=if from==1 then 0.001 else 1.0;let tf=if to==1 then 0.001 else 1.0
    let converted=(Float64(value)*sf)/tf
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    let bits=bitcast[UInt64](converted)
    for b in range(8):o[b]=UInt8((bits>>UInt(8*b))&255)
    return 8
