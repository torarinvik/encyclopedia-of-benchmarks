from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("k_folds")
fn k_folds(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or a[0]<1 or a[0]>12 or a[1]<1 or a[1]>12:return -1
    let samples=Int(a[0]);let folds=Int(a[1]);let width=(samples+folds-1)//folds;var result=Int64(samples)<<48
    for i in range(samples):result|=Int64((i//width)+1)<<(4*i)
    return result
