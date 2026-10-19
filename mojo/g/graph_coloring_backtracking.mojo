from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gcb_recurse(adj:InlineArray[Bool,4096],count:Int,vertex:Int,mut colors:InlineArray[Int64,64])->Bool:
    if vertex==count:return True
    for color in range(1,count+1):
        var safe=True
        for nb in range(count):
            if adj[vertex*64+nb] and colors[nb]==Int64(color):safe=False;break
        if safe:
            colors[vertex]=Int64(color)
            if gcb_recurse(adj,count,vertex+1,colors):return True
            colors[vertex]=0
    return False
fn gcb_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
@export("graph_coloring_backtracking")
fn graph_coloring_backtracking(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<0 or v[0]>64 or v[1]<0 or v[1]>2016:return -1
    let count=Int(v[0]);let edges=Int(v[1]);if n!=c_size_t(2+2*edges):return -1
    var adj=InlineArray[Bool,4096](fill=False)
    for e in range(edges):
        let a=v[2+2*e];let b=v[3+2*e];if a<0 or a>=count or b<0 or b>=count or a==b:return -1
        adj[Int(a)*64+Int(b)]=True;adj[Int(b)*64+Int(a)]=True
    var colors=InlineArray[Int64,64](fill=0)
    if not gcb_recurse(adj,count,0,colors):return -1
    var used:Int64=0
    for i in range(count):if colors[i]>used:used=colors[i]
    let values=count+2;let bytes=values*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    gcb_put(out,0,Int64(count))
    for i in range(count):gcb_put(out,(i+1)*8,colors[i])
    gcb_put(out,(count+1)*8,used);return Int64(bytes)
