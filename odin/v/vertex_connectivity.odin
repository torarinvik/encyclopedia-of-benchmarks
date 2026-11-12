package vertex_connectivity

import "core:c"

@(export)
vertex_connectivity :: proc "c" (input:[^]i64, length:c.size_t)->i64 {
    N :: 10; M :: 45; MAX_INPUT :: 92; DN :: 20
    if input==nil || length<2 || length>MAX_INPUT do return -1
    if input[0]<0 || input[0]>N || input[1]<0 || input[1]>M do return -1
    n,m:=int(input[0]),int(input[1])
    if length!=c.size_t(2+2*m) do return -1
    var adjacency:[N]u64
    for e:=0; e<m; e+=1 {
        left,right:=input[2+2*e],input[3+2*e]
        if left<0 || right<0 || left>=i64(n) || right>=i64(n) do return -1
        if left!=right { adjacency[int(left)] |= u64(1)<<u64(right); adjacency[int(right)] |= u64(1)<<u64(left) }
    }
    if n<=1 do return 0
    var reached:u64=1; var graph_queue:[N]int
    graph_head,graph_tail:=0,0; graph_queue[graph_tail]=0; graph_tail+=1
    for graph_head<graph_tail {
        u:=graph_queue[graph_head]; graph_head+=1
        for v:=0; v<n; v+=1 {
            bit:=u64(1)<<u64(v)
            if adjacency[u]&bit!=0 && reached&bit==0 { reached|=bit; graph_queue[graph_tail]=v; graph_tail+=1 }
        }
    }
    if reached!=((u64(1)<<u64(n))-1) do return 0
    best:=n-1
    for source:=0; source<n; source+=1 {
        for target:=source+1; target<n; target+=1 {
            if adjacency[source]&(u64(1)<<u64(target))!=0 do continue
            var residual:[DN*DN]int
            nodes:=2*n
            for v:=0; v<n; v+=1 {
                capacity:=1
                if v==source || v==target { capacity=n }
                residual[(2*v)*DN+2*v+1]=capacity
            }
            for u:=0; u<n; u+=1 {
                for v:=u+1; v<n; v+=1 {
                    if adjacency[u]&(u64(1)<<u64(v))!=0 { residual[(2*u+1)*DN+2*v]=1; residual[(2*v+1)*DN+2*u]=1 }
                }
            }
            start,sink:=2*source+1,2*target
            flow:=0
            for flow<best {
                var parent:[DN]int
                for v:=0; v<nodes; v+=1 { parent[v]=-1 }
                var queue:[DN]int; head,tail:=0,0; parent[start]=start; queue[tail]=start; tail+=1
                for head<tail && parent[sink]<0 {
                    u:=queue[head]; head+=1
                    for v:=0; v<nodes; v+=1 {
                        if parent[v]<0 && residual[u*DN+v]>0 { parent[v]=u; queue[tail]=v; tail+=1; if v==sink do break }
                    }
                }
                if parent[sink]<0 do break
                amount:=best-flow; v:=sink
                for v!=start { u:=parent[v]; if residual[u*DN+v]<amount { amount=residual[u*DN+v] }; v=u }
                v=sink
                for v!=start { u:=parent[v]; residual[u*DN+v]-=amount; residual[v*DN+u]+=amount; v=u }
                flow+=amount
            }
            if flow<best { best=flow }
            if best==0 do return 0
        }
    }
    return i64(best)
}
