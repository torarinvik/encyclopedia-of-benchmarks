from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("resistor_equivalence")
fn resistor_equivalence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>33:return -1.0e300
    let op=v[0];if op!=0 and op!=1:return -1.0e300
    var acc:Float64=0.0
    for i in range(1,Int(n)):
        let x=v[i];if x<0 or x>1000 or (op==0 and x==0):return -1.0e300
        if op==0:acc+=1.0/Float64(x)
        else:acc+=Float64(x)
    if op==0:return 1.0/acc
    return acc
