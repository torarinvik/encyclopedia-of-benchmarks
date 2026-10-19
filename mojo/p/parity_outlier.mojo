from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("parity_outlier")
fn parity_outlier(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<3 or v[0]>65 or v[0]%2==0 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var evens=0;var odds=0;var even:Int64=0;var odd:Int64=0
    for i in range(count):let x=v[i+1];if x<0 or x>2147483647:return -1;if x%2==0:evens+=1;even=x else:odds+=1;odd=x
    if evens==1 and odds>=2:return even
    if odds==1 and evens>=2:return odd
    return -1
