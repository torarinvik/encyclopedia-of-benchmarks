from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn hp_store(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,v:Int64):
    let u=bitcast[UInt32](Int32(v))
    for b in range(4):out[at+b]=UInt8((u>>UInt(8*b))&255)
@export("heap_permutation")
fn heap_permutation(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1
    let k=a[0];if k<0 or k>7 or n!=c_size_t(k+1):return -1
    var vals=InlineArray[Int64,7](fill=0)
    for i in range(Int(k)):
        if a[i+1]< -2147483648 or a[i+1]>2147483647:return -1
        vals[i]=a[i+1]
    var factorial=1
    for i in range(2,Int(k)+1):factorial*=i
    let bytes=factorial*Int(k)*4
    if cap<c_size_t(bytes) or (bytes>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    if k==0:return 1
    var ks=InlineArray[Int,8](fill=0);var is=InlineArray[Int,8](fill=0);var depth=0;ks[0]=Int(k)
    var rows=0
    while depth>=0:
        if ks[depth]<=1:
            for j in range(Int(k)):hp_store(out,(rows*Int(k)+j)*4,vals[j])
            rows+=1;depth-=1
        elif is[depth]<ks[depth]:
            let i=is[depth];let end=ks[depth]-1;let swap=i if ks[depth]%2==0 else 0
            let t=vals[swap];vals[swap]=vals[end];vals[end]=t
            is[depth]+=1;depth+=1;ks[depth]=ks[depth-1]-1;is[depth]=0
        else:depth-=1
    return Int64(rows)
