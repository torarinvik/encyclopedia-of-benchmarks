from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("neural_network_perceptron_classifier")
fn neural_network_perceptron_classifier(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>18:return -1
    let f=a[0];let samples=a[1];let bias=a[2]
    if f<1 or f>3 or samples<1 or samples>4 or bias< -10000 or bias>10000 or n!=c_size_t(3+f+f*samples):return -1
    for i in range(Int(f)):if a[3+i]< -10000 or a[3+i]>10000:return -1
    for i in range(Int(f*samples)):if a[3+Int(f)+i]< -10 or a[3+Int(f)+i]>10:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(samples):return -2
    for s in range(Int(samples)):
        var z=bias
        for j in range(Int(f)):z+=a[3+j]*a[3+Int(f)+j*Int(samples)+s]
        o[s]=1 if z>0 else 0
    return samples
