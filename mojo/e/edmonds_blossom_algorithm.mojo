from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn blossom_lca(a0:Int,b0:Int,n:Int,match:InlineArray[Int64,20],parent:InlineArray[Int64,20],base:InlineArray[Int64,20])->Int:
    var path=InlineArray[Int64,20](fill=0);var a=a0;var b=b0
    while True:
        a=Int(base[a]);path[a]=1
        if match[a]== -1:break
        a=Int(parent[Int(match[a])])
    while True:
        b=Int(base[b])
        if path[b]!=0:return b
        b=Int(parent[Int(match[b])])
    return 0
fn blossom_mark_path(mut parent:InlineArray[Int64,20],mut blossom:InlineArray[Int64,20],match:InlineArray[Int64,20],base:InlineArray[Int64,20],v0:Int,b:Int,child0:Int):
    var v=v0;var child=child0
    while base[v]!=b:
        blossom[Int(base[v])]=1;blossom[Int(base[Int(match[v])])]=1
        parent[v]=child;child=Int(match[v]);v=Int(parent[Int(match[v])])
fn blossom_find_path(root:Int,n:Int,graph:InlineArray[Int64,400],mut match:InlineArray[Int64,20],mut parent:InlineArray[Int64,20],mut base:InlineArray[Int64,20],mut used:InlineArray[Int64,20],mut blossom:InlineArray[Int64,20],mut queue:InlineArray[Int64,20])->Int:
    for i in range(n):used[i]=0;parent[i]= -1;base[i]=i
    var head=0;var tail=0;queue[tail]=root;tail+=1;used[root]=1
    while head<tail:
        let v=Int(queue[head]);head+=1
        for u in range(n):
            if graph[v*20+u]==0 or base[v]==base[u] or match[v]==u:continue
            if u==root or (match[u]!= -1 and parent[Int(match[u])]!= -1):
                let cur=blossom_lca(v,u,n,match,parent,base)
                for i in range(n):blossom[i]=0
                blossom_mark_path(parent,blossom,match,base,v,cur,u);blossom_mark_path(parent,blossom,match,base,u,cur,v)
                for i in range(n):
                    if blossom[Int(base[i])]!=0:
                        base[i]=cur
                        if used[i]==0:used[i]=1;queue[tail]=i;tail+=1
            elif parent[u]== -1:
                parent[u]=v
                if match[u]== -1:return u
                let next=Int(match[u]);used[next]=1;queue[tail]=next;tail+=1
    return -1

@export("edmonds_blossom_algorithm")
fn edmonds_blossom_algorithm(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>382:return -1
    let nn=input[0];let mm=input[1]
    if nn<0 or nn>20 or mm<0 or mm>190 or length!=c_size_t(2+2*mm):return -1
    let n=Int(nn);var graph=InlineArray[Int64,400](fill=0);var match=InlineArray[Int64,20](fill= -1)
    for i in range(Int(mm)):
        let a=input[2+2*i];let b=input[3+2*i]
        if a<0 or a>=nn or b<0 or b>=nn or a==b:return -1
        graph[Int(a)*20+Int(b)]=1;graph[Int(b)*20+Int(a)]=1
    var parent=InlineArray[Int64,20](fill= -1);var base=InlineArray[Int64,20](fill=0);var used=InlineArray[Int64,20](fill=0);var blossom=InlineArray[Int64,20](fill=0);var queue=InlineArray[Int64,20](fill=0)
    var answer=0
    for i in range(n):
        if match[i]!= -1:continue
        var v=blossom_find_path(i,n,graph,match,parent,base,used,blossom,queue)
        while v!= -1:
            let pv=Int(parent[v]);let next=Int(match[pv]);match[v]=pv;match[pv]=v;v=next
        if match[i]!= -1:answer+=1
    return answer
