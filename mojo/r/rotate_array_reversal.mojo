from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn rev32ra(a:UnsafePointer[Int32,MutAnyOrigin],s:Int,e:Int):
    var l=s;var r=e
    while l<r:r-=1;if l>=r:break;let t=a[l];a[l]=a[r];a[r]=t;l+=1
fn wr32rar(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int32):
    let b=UInt32(x);for j in range(4):o[at+j]=UInt8((b>>(8*j))&UInt32(255))
@export("rotate_array_reversal")
fn rotate_array_reversal(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025:return -1
    let steps=v[0];if steps< -2147483648 or steps>2147483647:return -1
    let count=Int(n)-1;var a=InlineArray[Int32,1024](fill=0)
    for i in range(count):let x=v[i+1];if x< -2147483648 or x>2147483647:return -1;a[i]=Int32(x)
    if cap<c_size_t(count*4):return -2
    let shift=if count==0:0 else:Int(((steps%Int64(count))+Int64(count))%Int64(count))
    var l=0;var r=count
    while l<r:r-=1;if l>=r:break;let t=a[l];a[l]=a[r];a[r]=t;l+=1
    l=0;r=shift
    while l<r:r-=1;if l>=r:break;let t=a[l];a[l]=a[r];a[r]=t;l+=1
    l=shift;r=count
    while l<r:r-=1;if l>=r:break;let t=a[l];a[l]=a[r];a[r]=t;l+=1
    for i in range(count):wr32rar(o,4*i,a[i])
    return Int64(count)
