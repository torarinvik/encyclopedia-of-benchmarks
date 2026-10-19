from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mtbt_valid(v:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,count:Int)->Bool:
    for i in range(count):
        let x=v[start+i]
        if x != -1000001 and (x < -100000 or x>100000):return False
        if i>0 and v[start+(i-1)//2]==-1000001 and x != -1000001:return False
    return True
fn mtbt_store(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):out[p+b]=UInt8((u>>(b*8))&255)
@export("merge_two_binary_trees")
fn merge_two_binary_trees(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>512:return -1
    let a=v[0]
    if a<0 or a>255 or Int(n)<Int(a)+2:return -1
    let bc=Int(a)+1;let b=v[bc]
    if b<0 or b>255 or Int(n)!=bc+1+Int(b):return -1
    let s1=1;let s2=bc+1
    if not mtbt_valid(v,s1,Int(a)) or not mtbt_valid(v,s2,Int(b)):return -1
    let slots=Int(max(a,b));var merged=InlineArray[Int32,255](fill=0);var nodes=0
    for i in range(slots):
        let x=if i<Int(a):v[s1+i] else:-1000001;let y=if i<Int(b):v[s2+i] else:-1000001
        if x == -1000001 and y == -1000001:merged[i]=Int32(-1000001)
        else:
            merged[i]=Int32((if x == -1000001:0 else:x)+(if y == -1000001:0 else:y));nodes+=1
    var used=slots
    while used>0 and merged[used-1]==Int32(-1000001):used-=1
    if cap<c_size_t(used*4) or (used>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(used):mtbt_store(out,i*4,merged[i])
    return nodes
