from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gc_hash(h0:UInt64,val:Int64)->UInt64:
    var h=h0;let x=UInt64(val)
    for i in range(8):h=(h^((x>>UInt64(8*i))&255))*UInt64(0x100000001b3)
    return h
@export("gcounter")
fn gcounter(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>386 or v[0]<1 or v[0]>8 or v[1]<0 or v[1]>128 or n!=c_size_t(2+3*v[1]):return -1
    let nodes=Int(v[0]);var state=InlineArray[Int64,64](fill=0);var hash=UInt64(0xcbf29ce484222325)
    for i in range(Int(v[1])):
        let op=v[2+3*i];let aa=v[3+3*i];let bb=v[4+3*i]
        if aa<0 or aa>=nodes:return -1
        if op==0:
            if bb!=0 or state[Int(aa)*8+Int(aa)]>=1000000:return -1
            state[Int(aa)*8+Int(aa)]+=1
        elif op==1:
            if bb!=0:return -1
            var total:Int64=0
            for j in range(nodes):total+=state[Int(aa)*8+j]
            hash=gc_hash(hash,total)
        elif op==2:
            if bb<0 or bb>=nodes:return -1
            var yes=1
            for j in range(nodes):if state[Int(aa)*8+j]>state[Int(bb)*8+j]:yes=0
            hash=gc_hash(hash,Int64(yes))
        elif op==3:
            if bb<0 or bb>=nodes:return -1
            for j in range(nodes):if state[Int(bb)*8+j]>state[Int(aa)*8+j]:state[Int(aa)*8+j]=state[Int(bb)*8+j]
        else:return -1
    for i in range(nodes):
        for j in range(nodes):hash=gc_hash(hash,state[i*8+j])
    return Int64(hash)
