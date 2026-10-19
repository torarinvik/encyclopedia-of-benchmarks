from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr32ra2(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int32):
    let b=UInt32(x);for j in range(4):o[at+j]=UInt8((b>>(8*j))&UInt32(255))
@export("rotate_array")
fn rotate_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025 or v[0]<0 or v[0]>1024:return -1
    let count=Int(n)-1;let rotations=Int(v[0]);if rotations>1024:return -1
    var a=InlineArray[Int32,1024](fill=0)
    for i in range(count):let x=v[i+1];if x< -2147483648 or x>2147483647:return -1;a[i]=Int32(x)
    if cap<c_size_t(count*4):return -2
    for _ in range(rotations):
        if count>1:let last=a[count-1];for i in range(1,count):let j=count-i;a[j]=a[j-1];a[0]=last
    for i in range(count):wr32ra2(o,4*i,a[i])
    return Int64(count)
