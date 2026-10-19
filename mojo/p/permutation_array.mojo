from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pa_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):o[p+4*b]=UInt8((u>>(8*b))&255)
fn pa_gen(mut a:InlineArray[Int32,6],n:Int,index:Int,o:UnsafePointer[UInt8,MutAnyOrigin],mut count:Int):
    if index==n:
        for j in range(n):pa_put(o,(count*n+j)*4,a[j])
        count+=1;return
    for p in range(index,n):
        let x=a[index];a[index]=a[p];a[p]=x;pa_gen(mut a,n,index+1,o,mut count);let y=a[index];a[index]=a[p];a[p]=y
@export("permutation_array")
fn permutation_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>8 or v[0]<0 or v[0]>6 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var a=InlineArray[Int32,6](fill=0)
    for i in range(count):if v[i+1] < -2147483648 or v[i+1]>2147483647:return -1;a[i]=Int32(v[i+1])
    var factorial=1;for i in range(2,count+1):factorial*=i
    let bytes=factorial*count*4;if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var generated=0;pa_gen(mut a,count,0,o,mut generated);return Int64(generated)
