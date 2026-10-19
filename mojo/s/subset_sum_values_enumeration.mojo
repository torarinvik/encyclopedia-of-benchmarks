from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn enum_values(a:UnsafePointer[Int64,ImmutAnyOrigin],items:Int,index:Int,target:Int64,total:Int64,chosen:UnsafePointer[Int64,MutAnyOrigin],chosen_n:Int,out:UnsafePointer[UInt8,MutAnyOrigin],pos:UnsafePointer[Int,MutAnyOrigin],emit:Bool)->Int:
    if total==target:
        if emit:
            let len=Int64(chosen_n);let lb=bitcast[UInt64](len)
            for b in range(8):out[pos[0]]=UInt8((lb>>UInt(8*b))&255);pos[0]+=1
            for i in range(chosen_n):
                let bits=bitcast[UInt64](chosen[i])
                for b in range(8):out[pos[0]]=UInt8((bits>>UInt(8*b))&255);pos[0]+=1
        return chosen_n+1
    if index==items or total>target:return 0
    chosen[chosen_n]=a[index+1]
    let x=enum_values(a,items,index+1,target,total+a[index+1],chosen,chosen_n+1,out,pos,emit)
    let y=enum_values(a,items,index+1,target,total,chosen,chosen_n,out,pos,emit)
    return x+y
@export("subset_sum_values_enumeration")
fn subset_sum_values_enumeration(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>12:return -1
    let target=v[0];let items=Int(n)-1
    if target<0 or target>256:return -1
    for i in range(items):if v[i+1]<1 or v[i+1]>64:return -1
    var chosen=InlineArray[Int64,11](fill=0);var pos=InlineArray[Int,1](0)
    let slots=enum_values(v,items,0,target,0,chosen.unsafe_ptr(),0,UnsafePointer[UInt8,MutAnyOrigin](),pos.unsafe_ptr(),False)
    let bytes=slots*8
    if bytes==0:return 0
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    pos[0]=0;enum_values(v,items,0,target,0,chosen.unsafe_ptr(),0,o,pos.unsafe_ptr(),True)
    return Int64(pos[0])
