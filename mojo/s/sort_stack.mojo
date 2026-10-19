from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn stack_insert(a:UnsafePointer[Int32,MutAnyOrigin],size:Int,value:Int32):Int:
    if size==0 or value>a[size-1]:a[size]=value;return size+1
    let top=a[size-1];let next=stack_insert(a,size-1,value);a[next]=top;return next+1
fn sort_rec(a:UnsafePointer[Int32,MutAnyOrigin],size:Int)->Int:
    if size==0:return 0
    let top=a[size-1];let reduced=sort_rec(a,size-1);return stack_insert(a,reduced,top)
@export("sort_stack")
fn sort_stack(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65:return -1
    let count=v[0]
    if count<0 or count>64 or n!=c_size_t(1+count):return -1
    var a=InlineArray[Int32,64](fill=0)
    for i in range(Int(count)):
        if v[1+i]< -2147483648 or v[1+i]>2147483647:return -1
        a[i]=Int32(v[1+i])
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(Int(count)*4):return -2
    let size=sort_rec(a.unsafe_ptr(),Int(count))
    for i in range(size):
        let bits=bitcast[UInt32](a[i]);for b in range(4):o[i*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(size*4)
