from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn rsf_shuff(mut v:InlineArray[Int64,64],item:Int,mut state:UInt64):
    if item<=0:return
    rsf_shuff(v,item-1,state);state=(state*48271)%2147483647;let other=Int(state%UInt64(item+1));let t=v[item];v[item]=v[other];v[other]=t
@export("recursive_shuffler")
fn recursive_shuffler(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65 or v[0]<1 or v[0]>=2147483647:return -1
    let count=Int(n)-1;var values=InlineArray[Int64,64](fill=0)
    for i in range(count):if v[i+1] < -2147483648 or v[i+1]>2147483647:return -1;values[i]=v[i+1]
    let bytes=count*4
    if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var state=UInt64(v[0]);if count>1:rsf_shuff(values,count-1,state)
    for i in range(count):
        let b=UInt32(Int32(values[i]))
        for j in range(4):o[i*4+j]=UInt8((b>>(8*j))&255)
    return Int64(count)
