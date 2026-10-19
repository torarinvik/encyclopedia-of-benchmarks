from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gj_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
fn gj_dfs(start:Int,adj:InlineArray[Int,13312],degree:InlineArray[Int,26],mut visited:InlineArray[Bool,26],mut result:InlineArray[Int64,645],mut pos:Int,mut count:Int):
    if visited[start]:return
    visited[start]=True;result[pos]=Int64(97+start);pos+=1;count+=1
    for e in range(degree[start]):gj_dfs(adj[start*512+e],adj,degree,visited,result,pos,count)
@export("graph_js_undirected_unweighted")
fn graph_js_undirected_unweighted(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>541 or v[0]<1 or v[0]>26:return -1
    let count=Int(v[0]);if n<c_size_t(count+3):return -1
    var declared=InlineArray[Bool,26](fill=False);var vertices=InlineArray[Int,26](fill=0)
    for i in range(count):
        let x=v[1+i];if x<97 or x>122:return -1
        let id=Int(x-97);if declared[id]:return -1;declared[id]=True;vertices[i]=id
    let eoff=1+count;let edges=Int(v[eoff]);if edges<0 or edges>256 or n!=c_size_t(count+2+2*edges):return -1
    var adj=InlineArray[Int,13312](fill=0);var degree=InlineArray[Int,26](fill=0);var pos=eoff+1
    for e in range(edges):
        let av=v[pos];let bv=v[pos+1];pos+=2;if av<97 or av>122 or bv<97 or bv>122:return -1
        let a=Int(av-97);let b=Int(bv-97)
        if declared[a] and declared[b]:
            if degree[a]>=512 or degree[b]>=512:return -1
            adj[a*512+degree[a]]=b;degree[a]+=1;adj[b*512+degree[b]]=a;degree[b]+=1
    let startv=v[pos];if startv<97 or startv>122:return -1;let start=Int(startv-97);if not declared[start]:return -1
    var result=InlineArray[Int64,645](fill=0);var used=0;result[used]=Int64(count);used+=1
    for i in range(count):
        let x=vertices[i];result[used]=Int64(97+x);used+=1;result[used]=Int64(degree[x]);used+=1
        for e in range(degree[x]):result[used]=Int64(97+adj[x*512+e]);used+=1
    var visited=InlineArray[Bool,26](fill=False);var queue=InlineArray[Int,513](fill=0);var levels=InlineArray[Int,513](fill=0);let bfs_slot=used;used+=1;var head=0;var tail=0;var bfs_count=0
    queue[tail]=start;levels[tail]=0;tail+=1
    while head<tail:
        let node=queue[head];let level=levels[head];head+=1
        if visited[node]:continue
        visited[node]=True;result[used]=Int64(97+node);used+=1;result[used]=Int64(level);used+=1;bfs_count+=1
        for e in range(degree[node]):queue[tail]=adj[node*512+e];levels[tail]=level+1;tail+=1
    result[bfs_slot]=Int64(bfs_count)
    for i in range(26):visited[i]=False
    let dfs_slot=used;used+=1;var dfs_count=0;gj_dfs(start,adj,degree,visited,result,used,dfs_count);result[dfs_slot]=Int64(dfs_count)
    let bytes=used*8;if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(used):gj_put(out,i,result[i])
    return Int64(bytes)
