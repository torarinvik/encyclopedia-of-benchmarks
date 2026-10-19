from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn permute(vals:InlineArray[Int,6],n:Int,depth:Int,current:InlineArray[Int,6],used:InlineArray[UInt8,6],out:UnsafePointer[UInt8,MutAnyOrigin],base:Int) -> Int:
    if depth==n:
        for i in range(n):out[base*n+i]=UInt8(vals[current[i]])
        return 1
    var total=0
    for i in range(n):
        if used[i]!=0:continue
        if i>0 and vals[i]==vals[i-1] and used[i-1]==0:continue
        var next_used=used;next_used[i]=1;var next_current=current;next_current[depth]=i
        total+=permute(vals,n,depth+1,next_current,next_used,out,base+total)
    return total
@export("unique_permutation")
fn unique_permutation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>7:return -1
    let count=v[0]
    if count<0 or count>6 or n!=c_size_t(count+1):return -1
    var vals=InlineArray[Int,6](fill=0)
    for i in range(Int(count)):
        if v[i+1]<0 or v[i+1]>127:return -1
        vals[i]=Int(v[i+1])
    for i in range(Int(count)):
        for j in range(i+1,Int(count)):
            if vals[j]<vals[i]:let t=vals[i];vals[i]=vals[j];vals[j]=t
    var maxrows=1
    for i in range(2,Int(count)+1):maxrows*=i
    let bytes=maxrows*Int(count)
    if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var current=InlineArray[Int,6](fill=0);var used=InlineArray[UInt8,6](fill=0)
    if count==0:return 1
    return Int64(permute(vals,Int(count),0,current,used,o,0))
