from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gs_put32(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,value:Int):
    let bits=UInt32(value)
    for b in range(4):out[pos+b]=UInt8((bits>>UInt32(8*b))&255)

fn gs_emit(v:UnsafePointer[Int64,ImmutAnyOrigin],count:Int,index:Int,mask:Int,selected:Int,out:UnsafePointer[UInt8,MutAnyOrigin],pos0:Int)->Int:
    if index==count:
        var pos=pos0;gs_put32(out,pos,selected);pos+=4
        for i in range(count):
            if (mask&(1<<i))!=0:out[pos]=UInt8(v[i+1]);pos+=1
        return pos
    let with_item=gs_emit(v,count,index+1,mask|(1<<index),selected+1,out,pos0)
    return gs_emit(v,count,index+1,mask,selected,out,with_item)

@export("generate_subsets_recursive")
fn generate_subsets_recursive(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>13 or v[0]<0 or v[0]>12:return -1
    let count=Int(v[0]);if n!=c_size_t(count+1):return -1
    for i in range(count):if v[i+1]<0 or v[i+1]>127:return -1
    let subsets=1<<count;let needed=4+4*subsets+count*(subsets//2)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    gs_put32(out,0,subsets)
    return Int64(gs_emit(v,count,0,0,0,out,4))
