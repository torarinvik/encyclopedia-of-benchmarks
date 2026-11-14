// Independent event-graph draft; compilation and output remain unverified.
module range_constraint_topological_feasibility

struct RctGraph {
mut:
    head []int
    degree []int
    first []bool
    to []int
    next []int
    nodes int
    edges int
}
struct RctTrees {
mut:
    down []int
    up []int
    any []int
}
fn new_node(mut g RctGraph, first bool) int {
    node:=g.nodes
    g.nodes++
    g.head[node]=-1
    g.degree[node]=0
    g.first[node]=first
    return node
}
fn add_edge(mut g RctGraph, source int, target int) {
    edge:=g.edges
    g.edges++
    g.to[edge]=target
    g.next[edge]=g.head[source]
    g.head[source]=edge
    g.degree[target]++
}
fn build(mut g RctGraph, mut t RctTrees, node int, left int, right int) {
    t.down[node]=new_node(mut g,false)
    t.up[node]=new_node(mut g,false)
    t.any[node]=new_node(mut g,true)
    if right-left==1 {
        add_edge(mut g,t.down[node],left)
        add_edge(mut g,left,t.up[node])
        add_edge(mut g,left,t.any[node])
        return
    }
    middle:=left+(right-left)/2
    build(mut g,mut t,2*node,left,middle)
    build(mut g,mut t,2*node+1,middle,right)
    for child in 2*node .. 2*node+2 {
        add_edge(mut g,t.down[node],t.down[child])
        add_edge(mut g,t.up[child],t.up[node])
        add_edge(mut g,t.any[child],t.any[node])
    }
}
fn connect(mut g RctGraph, t RctTrees, node int, left int, right int,
           ql int, qr int, kind int, target int) {
    if ql<=left && right<=qr {
        if kind==1 { add_edge(mut g,target,t.down[node]) }
        else if kind==2 { add_edge(mut g,t.up[node],target) }
        else { add_edge(mut g,t.any[node],target) }
        return
    }
    middle:=left+(right-left)/2
    if ql<middle { connect(mut g,t,2*node,left,middle,ql,qr,kind,target) }
    if qr>middle { connect(mut g,t,2*node+1,middle,right,ql,qr,kind,target) }
}

@[export: 'range_constraint_topological_feasibility']
pub fn range_constraint_topological_feasibility(input &i64, length usize) i64 {
    if length<2 { return -1 }
    unsafe {
        if input==nil || input[0]<1 || input[0]>4096 || input[1]<0 || input[1]>8192 { return -1 }
        n:=int(input[0]); m:=int(input[1])
        if length!=usize(2+4*m) { return -1 }
        for i in 0 .. m {
            kind,left,right,target:=input[2+4*i],input[3+4*i],input[4+4*i],input[5+4*i]
            if kind<1 || kind>3 || left<0 || left>=right || right>i64(n) || target<0 ||
                target>=i64(n) || (left<=target && target<right) { return -1 }
        }
        node_cap:=7*n+m+1; edge_cap:=9*n+32*m+1
        mut g:=RctGraph{head: []int{len:node_cap}, degree: []int{len:node_cap},
                        first: []bool{len:node_cap}, to: []int{len:edge_cap}, next: []int{len:edge_cap}}
        mut trees:=RctTrees{down: []int{len:4*n}, up: []int{len:4*n}, any: []int{len:4*n}}
        for _ in 0 .. n { new_node(mut g,false) }
        build(mut g,mut trees,1,0,n)
        for i in 0 .. m {
            kind,left,right,target:=int(input[2+4*i]),int(input[3+4*i]),int(input[4+4*i]),int(input[5+4*i])
            if kind==3 {
                gate:=new_node(mut g,true)
                connect(mut g,trees,1,0,n,left,right,kind,gate)
                add_edge(mut g,gate,target)
            } else { connect(mut g,trees,1,0,n,left,right,kind,target) }
        }
        mut queue:=[]int{len:node_cap}
        mut head:=0; mut tail:=0; mut emitted:=0
        for i in 0 .. g.nodes {
            if g.first[i] { g.degree[i]=1 }
            if g.degree[i]==0 { queue[tail]=i; tail++ }
        }
        for head<tail {
            node:=queue[head]; head++
            if node<n { emitted++ }
            mut edge:=g.head[node]
            for edge>=0 {
                target:=g.to[edge]
                if g.degree[target]>0 {
                    g.degree[target]--
                    if g.degree[target]==0 { queue[tail]=target; tail++ }
                }
                edge=g.next[edge]
            }
        }
        return if emitted==n { i64(1) } else { i64(0) }
    }
}
