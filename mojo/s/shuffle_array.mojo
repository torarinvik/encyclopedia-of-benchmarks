from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sha_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:Int64):
    let z=bitcast[UInt64](v);for b in range(8):o[p+b]=UInt8((z>>UInt(8*b))&255)
@export("shuffle_array")
fn shuffle_array(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>67:return -1
    let variant=a[0];let count=a[1];if (variant!=0 and variant!=1) or count<0 or count>32:return -1
    let vals=Int(count) if variant==0 else 2*Int(count);let draws=Int(count)-1 if variant==0 and count>0 else 0
    if n!=c_size_t(2+vals+draws):return -1
    var outv=InlineArray[Int64,64]()
    for i in range(vals):let x=a[i+2];if x< -2147483648 or x>2147483647:return -1;outv[i]=x
    if variant==0:
        for i in range(draws):let at=Int(count)-1-i;let d=a[2+Int(count)+i];if d<0 or d>at:return -1;let t=outv[at];outv[at]=outv[Int(d)];outv[Int(d)]=t
    else:
        for i in range(Int(count)):outv[2*i]=a[i+2];outv[2*i+1]=a[Int(count)+i+2]
    let bytes=(vals+1)*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    sha_put(o,0,Int64(vals));for i in range(vals):sha_put(o,(i+1)*8,outv[i])
    return Int64(bytes)
