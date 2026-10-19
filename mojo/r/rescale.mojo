from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("rescale")
fn rescale(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>260:return -1
    let m=v[0];let target=v[1];let draws=v[2]
    if m<2 or m>64 or target<1 or target>256 or draws<1 or draws>256 or Int(n)!=3+Int(draws):return -1
    for i in range(Int(draws)):if v[3+i]<0 or v[3+i]>=m:return -1
    if target==m:return v[3]
    var cursor=0
    if target<m:
        let threshold=m-m%target
        while cursor<Int(draws):let x=v[3+cursor];cursor+=1;if x<threshold:return x%target
        return -1
    var result:Int64=0;var power:Int64=1
    while power<target:
        if cursor>=Int(draws):return -1
        result+=power*v[3+cursor];cursor+=1;power*=m
    if power==target:return result
    let threshold=power-power%target
    while result>=threshold:
        result=0;power=1
        while power<target:
            if cursor>=Int(draws):return -1
            result+=power*v[3+cursor];cursor+=1;power*=m
    return result%target
