from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gsp_dfs(node:Int,dest:Int,adj:InlineArray[Int,8192],degree:InlineArray[Int,32],mut visited:InlineArray[Bool,32],mut path:InlineArray[Int,32],depth:Int)->Int:
    if visited[node]:return -1
    visited[node]=True
    if node==dest:return depth
    for i in range(degree[node]):
        let next=adj[node*256+i];path[depth]=next
        let result=gsp_dfs(next,dest,adj,degree,visited,path,depth+1)
        if result>=0:return result
    return -1
fn gsp_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
@export("graph_swift_directed_paths")
fn graph_swift_directed_paths(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1
    let count=Int(v[0]);let edges=Int(v[1]);if count<1 or count>32 or edges<0 or edges>256:return -1
    let qpos=2+2*edges;if n<c_size_t(qpos+1):return -1
    let queries=Int(v[qpos]);if queries<1 or queries>64 or n!=c_size_t(qpos+1+3*queries):return -1
    var adj=InlineArray[Int,8192](fill=0);var degree=InlineArray[Int,32](fill=0)
    for e in range(edges):
        let a=v[2+2*e];let b=v[3+2*e];if a<0 or a>=count or b<=a or b>=count:return -1
        adj[Int(a)*256+degree[Int(a)]]=Int(b);degree[Int(a)]+=1
    var modes=InlineArray[Int,64](fill=0);var starts=InlineArray[Int,64](fill=0);var dests=InlineArray[Int,64](fill=0)
    for i in range(queries):
        let p=qpos+1+3*i;let mode=v[p];let start=v[p+1];let dest=v[p+2]
        if mode<0 or mode>1 or start<0 or start>=count or dest<0 or dest>=count:return -1
        modes[i]=Int(mode);starts[i]=Int(start);dests[i]=Int(dest)
    var paths=InlineArray[Int,2048](fill=0);var lengths=InlineArray[Int,64](fill= -1);var total_words=0
    for qi in range(queries):
        let start=starts[qi];let dest=dests[qi];let base=qi*32
        if modes[qi]==0:
            var visited=InlineArray[Bool,32](fill=False);var path=InlineArray[Int,32](fill=0)
            let found=gsp_dfs(start,dest,adj,degree,visited,path,0);lengths[qi]=found
            if found>0:
                for j in range(found):paths[base+j]=path[j]
        else:
            var parent=InlineArray[Int,32](fill= -1);var queue=InlineArray[Int,32](fill=0);var head=0;var tail=0;parent[start]=start;queue[tail]=start;tail+=1
            while head<tail:
                let cur=queue[head];head+=1
                if cur==dest:break
                for j in range(degree[cur]):
                    let nx=adj[cur*256+j]
                    if parent[nx]== -1:parent[nx]=cur;queue[tail]=nx;tail+=1
            if parent[dest]>=0:
                var reverse=InlineArray[Int,32](fill=0);var cnt=0;var cur=dest
                while cur!=start:reverse[cnt]=cur;cnt+=1;cur=parent[cur]
                lengths[qi]=cnt
                for j in range(cnt):paths[base+j]=reverse[cnt-1-j]
        total_words+=1+(lengths[qi] if lengths[qi]>0 else 0)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(total_words*8):return -2
    var pos=0
    for qi in range(queries):
        gsp_put(out,pos,Int64(lengths[qi]));pos+=1
        for j in range(lengths[qi]):gsp_put(out,pos,Int64(paths[qi*32+j]));pos+=1
    return Int64(total_words*8)
