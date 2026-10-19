from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mk2_find(mut p:InlineArray[Int64,16],x0:Int)->Int:
    var x=x0
    while Int(p[x])!=x:p[x]=p[Int(p[x])];x=Int(p[x])
    return x
fn mk2_i32(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):out[pos+b]=UInt8((u>>(8*b))&255)
@export("minimum_spanning_tree_kruskal2")
fn minimum_spanning_tree_kruskal2(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n<2 or n>194:return -1
    let nv=v[0];let ne=v[1]
    if nv<1 or nv>16 or ne<0 or ne>64 or Int(n)!=2+3*Int(ne):return -1
    let vertices=Int(nv);let edges=Int(ne);var seen=InlineArray[Int64,256](fill=0);var order=InlineArray[Int64,64](fill=0)
    for i in range(edges):
        let u=Int(v[2+3*i]);let w=Int(v[3+3*i])
        if u<0 or w<=u or w>=vertices or seen[u*16+w]!=0:return -1
        seen[u*16+w]=1;order[i]=Int64(i)
    if vertices>1:
        var visited=InlineArray[Int64,16](fill=0);var stack=InlineArray[Int64,16](fill=0);var top=1;var reached=0;visited[0]=1
        while top>0:
            top-=1;let u=Int(stack[top]);reached+=1
            for w in range(vertices):
                if (seen[u*16+w]!=0 or seen[w*16+u]!=0) and visited[w]==0:visited[w]=1;stack[top]=Int64(w);top+=1
        if reached!=vertices:return -1
    for i in range(1,edges):
        let key=order[i];var j=i
        while j>0 and v[2+3*Int(order[j-1])+2]>v[2+3*Int(key)+2]:order[j]=order[j-1];j-=1
        order[j]=key
    var parent=InlineArray[Int64,16](fill=0);var rank=InlineArray[Int64,16](fill=0)
    for i in range(vertices):parent[i]=Int64(i)
    var chosen=InlineArray[Int64,16](fill=0);var count=0
    for z in range(edges):
        if count==vertices-1:break
        let e=Int(order[z]);let a=mk2_find(mut parent,Int(v[2+3*e]));let b=mk2_find(mut parent,Int(v[3+3*e]))
        if a!=b:
            if rank[a]<rank[b]:parent[a]=Int64(b)
            elif rank[a]>rank[b]:parent[b]=Int64(a)
            else:parent[a]=Int64(b);rank[b]+=1
            chosen[count]=Int64(e);count+=1
    if count!=vertices-1:return -1
    let bytes=(1+3*count)*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    mk2_i32(out,0,Int32(count))
    for i in range(count):let e=Int(chosen[i]);mk2_i32(out,4+12*i,v[2+3*e]);mk2_i32(out,8+12*i,v[3+3*e]);mk2_i32(out,12+12*i,v[4+3*e])
    return Int64(bytes)
