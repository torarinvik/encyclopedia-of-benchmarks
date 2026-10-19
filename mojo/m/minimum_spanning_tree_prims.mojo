from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn msp_sift(mut heap:InlineArray[Int64,16],mut pos:InlineArray[Int64,16],mut nodepos:InlineArray[Int64,16],size:Int,start:Int):
    var root=start
    while root*2+1<size:
        let left=root*2+1;let right=left+1;let child=if right>=size or heap[left]<heap[right]:left else:right
        if heap[child]>=heap[root]:break
        let h=heap[root];heap[root]=heap[child];heap[child]=h
        let p=pos[root];pos[root]=pos[child];pos[child]=p
        nodepos[Int(pos[root])]=Int64(root);nodepos[Int(pos[child])]=Int64(child);root=child
fn msp_decrease(value:Int64,mut index:Int,mut heap:InlineArray[Int64,16],mut pos:InlineArray[Int64,16],mut nodepos:InlineArray[Int64,16]):
    let vertex=pos[index]
    while index!=0:
        let parent=(index-1)//2
        if value<heap[parent]:heap[index]=heap[parent];pos[index]=pos[parent];nodepos[Int(pos[parent])]=Int64(index)
        else:heap[index]=value;pos[index]=vertex;nodepos[Int(vertex)]=Int64(index);return
        index=parent
    heap[0]=value;pos[0]=vertex;nodepos[Int(vertex)]=0
fn msp_i32(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):out[p+b]=UInt8((u>>(8*b))&255)
@export("minimum_spanning_tree_prims")
fn minimum_spanning_tree_prims(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n<2 or n>195:return -1
    let nv=v[0];let ne=v[1]
    if nv<1 or nv>16 or ne<0 or ne>64 or Int(n)!=2+3*Int(ne):return -1
    let vertices=Int(nv);let edges=Int(ne);var neigh=InlineArray[Int64,256](fill=0);var weights=InlineArray[Int64,256](fill=0);var degree=InlineArray[Int64,16](fill=0);var seen=InlineArray[Int64,256](fill=0)
    for i in range(edges):
        let u=Int(v[2+3*i]);let w=Int(v[3+3*i]);let weight=v[4+3*i]
        if u<0 or w<=u or w>=vertices or seen[u*16+w]!=0:return -1
        seen[u*16+w]=1
        let du=Int(degree[u]);neigh[u*16+du]=Int64(w);weights[u*16+du]=Int64(weight);degree[u]+=1
        let dw=Int(degree[w]);neigh[w*16+dw]=Int64(u);weights[w*16+dw]=Int64(weight);degree[w]+=1
    if vertices>1:
        var visited=InlineArray[Int64,16](fill=0);var stack=InlineArray[Int64,16](fill=0);var top=1;var reached=0;visited[0]=1
        while top>0:
            top-=1;let node=Int(stack[top]);reached+=1
            for j in range(Int(degree[node])):
                let x=Int(neigh[node*16+j])
                if visited[x]==0:visited[x]=1;stack[top]=Int64(x);top+=1
        if reached!=vertices:return -1
    var visited=InlineArray[Int64,16](fill=0);var parent=InlineArray[Int64,16](fill=-1);var heap=InlineArray[Int64,16](fill=9223372036854775807);var pos=InlineArray[Int64,16](fill=0);var nodepos=InlineArray[Int64,16](fill=0)
    for i in range(vertices):pos[i]=Int64(i);nodepos[i]=Int64(i)
    visited[0]=1
    for j in range(Int(degree[0])):
        let x=Int(neigh[j]);parent[x]=0;heap[x]=weights[j]
    for i in range(vertices//2):msp_sift(mut heap,mut pos,mut nodepos,vertices,vertices//2-1-i)
    var answer=InlineArray[Int64,16](fill=0);var count=0
    for _ in range(1,vertices):
        let node=Int(pos[0]);heap[0]=9223372036854775807;msp_sift(mut heap,mut pos,mut nodepos,vertices,0)
        if visited[node]==0:
            answer[1+2*count]=parent[node];answer[2+2*count]=Int64(node);count+=1;visited[node]=1
            for j in range(Int(degree[node])):
                let nb=Int(neigh[node*16+j]);let weight=weights[node*16+j]
                if visited[nb]==0:
                    let at=Int(nodepos[nb])
                    if weight<heap[at]:heap[at]=weight;msp_decrease(weight,at,mut heap,mut pos,mut nodepos);parent[nb]=Int64(node)
    if count!=vertices-1:return -1
    let bytes=4+count*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    msp_i32(out,0,Int32(count))
    for i in range(2*count):msp_i32(out,4+4*i,Int32(answer[i+1]))
    return Int64(bytes)
