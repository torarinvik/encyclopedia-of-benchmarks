# Uncompiled and unexecuted matrix-tree draft.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn resistance_minor(lap: List[Int64], n: Int, first: Int, second: Int) -> Int64:
    var matrix=List[Int64](length=36,fill=0)
    var rows=0
    for i in range(n):
        if i==first or i==second: continue
        var col=0
        for j in range(n):
            if j!=first and j!=second:
                matrix[rows*6+col]=lap[i*6+j]
                col+=1
        rows+=1
    if rows==0:return 1
    var previous:Int64=1
    for k in range(rows-1):
        let pivot=matrix[k*6+k]
        if pivot==0:return 0
        for i in range(k+1,rows):
            for j in range(k+1,rows):
                matrix[i*6+j]=(matrix[i*6+j]*pivot-matrix[i*6+k]*matrix[k*6+j])//previous
        for i in range(k+1,rows):matrix[i*6+k]=0
        previous=pivot
    return matrix[(rows-1)*6+rows-1]

@export("effective_resistance_unit_graph")
fn effective_resistance_unit_graph(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>35:return -1
    let nv=input[0];let mv=input[1];let sv=input[2];let tv=input[3]
    if nv<2 or nv>6 or mv<0 or mv>15 or sv<0 or sv>=nv or tv<0 or tv>=nv or sv==tv:return -1
    if length!=c_size_t(4+2*mv):return -1
    let n=Int(nv);let m=Int(mv);let s=Int(sv);let t=Int(tv)
    var lap=List[Int64](length=36,fill=0)
    var seen=List[Bool](length=36,fill=False)
    for i in range(m):
        let uv=input[4+2*i];let vv=input[5+2*i]
        if uv<0 or uv>=nv or vv<0 or vv>=nv or uv==vv:return -1
        let u=Int(uv);let v=Int(vv)
        if seen[u*6+v]:return -1
        seen[u*6+v]=True;seen[v*6+u]=True
        lap[u*6+u]+=1;lap[v*6+v]+=1;lap[u*6+v]-=1;lap[v*6+u]-=1
    let trees=resistance_minor(lap,n,t,-1)
    if trees<=0:return -1
    let forests=resistance_minor(lap,n,s,t)
    var a=trees;var b=forests
    while b!=0:
        let r=a%b
        a=b;b=r
    return (forests//a)*65536+trees//a
