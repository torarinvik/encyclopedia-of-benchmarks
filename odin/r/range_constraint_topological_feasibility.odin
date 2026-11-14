// Independent event-graph draft; compilation and output are unverified.
package range_constraint_topological_feasibility
import "core:c"

Graph :: struct {
    head, degree, first, edge_to, edge_next: []int,
    nodes, edges: int,
}
Trees :: struct { down, up, any: []int }

new_node :: proc(g: ^Graph, first: bool) -> int {
    id:=g.nodes; g.nodes+=1
    g.head[id]=-1; g.degree[id]=0
    if first { g.first[id]=1 }
    return id
}
add_edge :: proc(g: ^Graph, source, target: int) {
    edge:=g.edges; g.edges+=1
    g.edge_to[edge]=target; g.edge_next[edge]=g.head[source]; g.head[source]=edge
    g.degree[target]+=1
}
build :: proc(g: ^Graph, t: ^Trees, node, left, right: int) {
    t.down[node]=new_node(g,false); t.up[node]=new_node(g,false); t.any[node]=new_node(g,true)
    if right-left==1 {
        add_edge(g,t.down[node],left); add_edge(g,left,t.up[node]); add_edge(g,left,t.any[node])
        return
    }
    middle:=left+(right-left)/2
    build(g,t,2*node,left,middle); build(g,t,2*node+1,middle,right)
    for child:=2*node; child<=2*node+1; child+=1 {
        add_edge(g,t.down[node],t.down[child])
        add_edge(g,t.up[child],t.up[node])
        add_edge(g,t.any[child],t.any[node])
    }
}
connect :: proc(g: ^Graph, t: ^Trees, node, left, right, ql, qr, kind, target: int) {
    if ql<=left && right<=qr {
        if kind==1 { add_edge(g,target,t.down[node]) }
        else if kind==2 { add_edge(g,t.up[node],target) }
        else { add_edge(g,t.any[node],target) }
        return
    }
    middle:=left+(right-left)/2
    if ql<middle { connect(g,t,2*node,left,middle,ql,qr,kind,target) }
    if qr>middle { connect(g,t,2*node+1,middle,right,ql,qr,kind,target) }
}

@(export)
range_constraint_topological_feasibility :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<2 || input[0]<1 || input[0]>4096 || input[1]<0 || input[1]>8192 do return -1
    n,m:=int(input[0]),int(input[1])
    if length!=c.size_t(2+4*m) do return -1
    for i:=0; i<m; i+=1 {
        kind,l,r,v:=input[2+4*i],input[3+4*i],input[4+4*i],input[5+4*i]
        if kind<1 || kind>3 || l<0 || l>=r || r>i64(n) || v<0 || v>=i64(n) || (l<=v && v<r) do return -1
    }
    nodes:=7*n+m+1; edges:=9*n+32*m+1
    g:=Graph{head=make([]int,nodes), degree=make([]int,nodes), first=make([]int,nodes),
             edge_to=make([]int,edges), edge_next=make([]int,edges)}
    defer delete(g.head); defer delete(g.degree); defer delete(g.first)
    defer delete(g.edge_to); defer delete(g.edge_next)
    trees:=Trees{down=make([]int,4*n), up=make([]int,4*n), any=make([]int,4*n)}
    defer delete(trees.down); defer delete(trees.up); defer delete(trees.any)
    queue:=make([]int,nodes); defer delete(queue)
    for i:=0; i<n; i+=1 { _=new_node(&g,false) }
    build(&g,&trees,1,0,n)
    for i:=0; i<m; i+=1 {
        kind,l,r,target:=int(input[2+4*i]),int(input[3+4*i]),int(input[4+4*i]),int(input[5+4*i])
        if kind==3 {
            gate:=new_node(&g,true)
            connect(&g,&trees,1,0,n,l,r,kind,gate); add_edge(&g,gate,target)
        } else { connect(&g,&trees,1,0,n,l,r,kind,target) }
    }
    head,tail,emitted:=0,0,0
    for i:=0; i<g.nodes; i+=1 {
        if g.first[i]!=0 { g.degree[i]=1 }
        if g.degree[i]==0 { queue[tail]=i; tail+=1 }
    }
    for head<tail {
        node:=queue[head]; head+=1
        if node<n { emitted+=1 }
        edge:=g.head[node]
        for edge>=0 {
            target:=g.edge_to[edge]
            if g.degree[target]>0 {
                g.degree[target]-=1
                if g.degree[target]==0 { queue[tail]=target; tail+=1 }
            }
            edge=g.edge_next[edge]
        }
    }
    if emitted==n do return 1
    return 0
}
