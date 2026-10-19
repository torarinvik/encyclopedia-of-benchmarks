from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import exp
@export("simple_neural_network")
fn simple_neural_network(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    let expected=a[0];let init=a[1];let count=a[2]
    if expected<0 or expected>100 or init<1 or init>199 or init%2==0 or count<1 or count>65536:return -1.0e300
    let target=Float64(expected)/100.0;var weight=Float64(init);var layer=0.0
    for _ in range(Int(count)):layer=1.0/(1.0+exp(-0.02*weight));let err=target-layer;let delta=err*layer*(1.0-layer);weight+=0.02*delta
    return layer*100.0
