from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mst_find(mut p:InlineArray[Int64,64],x0:Int)->Int:
    var x=x0
    while Int(p[x])!=x:p[x]=p[Int(p[x])];x=Int(p[x])
    return x
fn mst_i64(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):out[pos+b]=UInt8((u>>(8*b))&255)
@export("minimum_spanning_tree_kruskal")
fn minimum_spanning_tree_kruskal(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>12290 or v[0]<0 or v[0]>64 or v[1]<0 or v[1]>4096 or Int(n)!=2+3*Int(v[1]):return -1
    let vertices=Int(v[0]);let edges=Int(v[1]);var order=InlineArray[Int64,4096](fill=0)
    for i in range(edges):
        let u=v[2+3*i];let w=v[3+3*i]
        if u<0 or u>=Int64(vertices) or w<0 or w>=Int64(vertices):return -1
        order[i]=Int64(i)
    for i in range(1,edges):
        let key=order[i];var j=i
        while j>0 and v[2+3*Int(order[j-1])+2]>v[2+3*Int(key)+2]:order[j]=order[j-1];j-=1
        order[j]=key
    var parent=InlineArray[Int64,64](fill=0)
    for i in range(vertices):parent[i]=Int64(i)
    var accepted=InlineArray[Int64,64](fill=0);var count=0
    for z in range(edges):
        let e=Int(order[z]);let a=mst_find(mut parent,Int(v[2+3*e]));let b=mst_find(mut parent,Int(v[3+3*e]))
        if a!=b:parent[a]=Int64(b);accepted[count]=Int64(e);count+=1
    let bytes=count*24
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):
        let e=Int(accepted[i]);mst_i64(out,24*i,v[2+3*e]);mst_i64(out,24*i+8,v[3+3*e]);mst_i64(out,24*i+16,v[4+3*e])
    return Int64(bytes)
