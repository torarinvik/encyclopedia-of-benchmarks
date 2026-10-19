from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn nn_append(mut out:InlineArray[UInt8,47],mut pos:Int,x:Int):
    if x>=10:nn_append(out,pos,x//10)
    out[pos]=UInt8(48+x%10);pos+=1
@export("nearest_neighbour_algorithm")
fn nearest_neighbour_algorithm(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>257 or a[0]<1 or a[0]>16:return -1
    let m=Int(a[0]);if n!=c_size_t(1+m*m):return -1
    for i in range(1,Int(n)):if a[i]<0 or a[i]>1000000:return -1
    var seen=InlineArray[Bool,16]();var path=InlineArray[Int64,16]();var cur=0
    for step in range(m):
        seen[cur]=True;path[step]=cur
        if step+1<m:
            var best=-1;var bd:Int64=0
            for j in range(m):if not seen[j]:let d=a[1+cur*m+j];if best<0 or d<bd:best=j;bd=d
            cur=best
    var bytes=InlineArray[UInt8,47]();var pos=0
    for i in range(m):if i>0:bytes[pos]=44;pos+=1;nn_append(bytes,pos,Int(path[i]))
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(pos):return -2
    for i in range(pos):o[i]=bytes[i]
    return pos
