from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("shuffle")
fn shuffle(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>513:return -1
    let raw=a[0];if raw!=Float64(Int64(raw)) or raw<0 or raw>256:return -1
    let count=Int(raw);let swaps=max(0,count-1);if n!=c_size_t(1+count+swaps):return -1
    var v=InlineArray[Float64,256]()
    for i in range(count):let x=a[i+1];if x!=Float64(Int64(x)) or x< -2147483648 or x>2147483647:return -1;v[i]=Float64(Int64(x))
    for i in range(swaps):let x=a[1+count+i];if x!=Float64(Int64(x)) or x<0 or x>count-1-i:return -1
    for i in range(swaps):let j=i+Int(a[1+count+i]);let t=v[i];v[i]=v[j];v[j]=t
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):o[i]=v[i]
    return Int64(count)
