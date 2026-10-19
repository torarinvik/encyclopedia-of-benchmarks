from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gm_recurse(v:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,m:Int,vertex:Int,mut colors:InlineArray[Int64,12])->Bool:
    if vertex==n:return True
    for color in range(m):
        var safe=True
        for neighbor in range(n):
            if v[2+vertex*n+neighbor]==1 and colors[neighbor]==Int64(color):safe=False;break
        if safe:
            colors[vertex]=Int64(color)
            if gm_recurse(v,n,m,vertex+1,colors):return True
            colors[vertex]= -1
    return False
fn gm_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
@export("graph_m_coloring_backtracking")
fn graph_m_coloring_backtracking(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<0 or v[0]>12 or v[1]<0 or v[1]>12:return -1
    let count=Int(v[0]);let m=Int(v[1]);if n!=c_size_t(2+count*count):return -1
    for r in range(count):
        if v[2+r*count+r]!=0:return -1
        for c in range(count):if (v[2+r*count+c]!=0 and v[2+r*count+c]!=1) or v[2+r*count+c]!=v[2+c*count+r]:return -1
    var colors=InlineArray[Int64,12](fill= -1)
    if not gm_recurse(v,count,m,0,colors):return 0
    let bytes=count*8;if bytes==0:return 0
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):gm_put(out,i,colors[i])
    return Int64(bytes)
