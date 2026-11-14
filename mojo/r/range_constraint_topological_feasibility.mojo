# Independent event-graph draft; compilation and output remain unverified.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn rct_node(first_flag: Int, mut head: List[Int], mut degree: List[Int],
            mut first: List[Int], mut counts: List[Int]) -> Int:
    let node=counts[0]
    counts[0]+=1
    head[node]=-1
    degree[node]=0
    first[node]=first_flag
    return node

fn rct_edge(source: Int, target: Int, mut head: List[Int], mut degree: List[Int],
            mut edge_to: List[Int], mut edge_next: List[Int], mut counts: List[Int]):
    let edge=counts[1]
    counts[1]+=1
    edge_to[edge]=target
    edge_next[edge]=head[source]
    head[source]=edge
    degree[target]+=1

fn rct_build(node: Int, left: Int, right: Int, mut down: List[Int], mut up: List[Int],
             mut any_tree: List[Int], mut head: List[Int], mut degree: List[Int],
             mut first: List[Int], mut edge_to: List[Int], mut edge_next: List[Int], mut counts: List[Int]):
    down[node]=rct_node(0,head,degree,first,counts)
    up[node]=rct_node(0,head,degree,first,counts)
    any_tree[node]=rct_node(1,head,degree,first,counts)
    if right-left==1:
        rct_edge(down[node],left,head,degree,edge_to,edge_next,counts)
        rct_edge(left,up[node],head,degree,edge_to,edge_next,counts)
        rct_edge(left,any_tree[node],head,degree,edge_to,edge_next,counts)
        return
    let middle=left+(right-left)//2
    rct_build(2*node,left,middle,down,up,any_tree,head,degree,first,edge_to,edge_next,counts)
    rct_build(2*node+1,middle,right,down,up,any_tree,head,degree,first,edge_to,edge_next,counts)
    for child in range(2*node,2*node+2):
        rct_edge(down[node],down[child],head,degree,edge_to,edge_next,counts)
        rct_edge(up[child],up[node],head,degree,edge_to,edge_next,counts)
        rct_edge(any_tree[child],any_tree[node],head,degree,edge_to,edge_next,counts)

fn rct_connect(node: Int, left: Int, right: Int, ql: Int, qr: Int, kind: Int, target: Int,
               down: List[Int], up: List[Int], any_tree: List[Int], mut head: List[Int],
               mut degree: List[Int], mut edge_to: List[Int], mut edge_next: List[Int], mut counts: List[Int]):
    if ql<=left and right<=qr:
        if kind==1: rct_edge(target,down[node],head,degree,edge_to,edge_next,counts)
        elif kind==2: rct_edge(up[node],target,head,degree,edge_to,edge_next,counts)
        else: rct_edge(any_tree[node],target,head,degree,edge_to,edge_next,counts)
        return
    let middle=left+(right-left)//2
    if ql<middle:
        rct_connect(2*node,left,middle,ql,qr,kind,target,down,up,any_tree,head,degree,edge_to,edge_next,counts)
    if qr>middle:
        rct_connect(2*node+1,middle,right,ql,qr,kind,target,down,up,any_tree,head,degree,edge_to,edge_next,counts)

@export("range_constraint_topological_feasibility")
fn range_constraint_topological_feasibility(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64, ImmutAnyOrigin]() or length<2: return -1
    if input[0]<1 or input[0]>4096 or input[1]<0 or input[1]>8192: return -1
    let n=Int(input[0])
    let m=Int(input[1])
    if length!=c_size_t(2+4*m): return -1
    for i in range(m):
        let kind=input[2+4*i]
        let left=input[3+4*i]
        let right=input[4+4*i]
        let target=input[5+4*i]
        if kind<1 or kind>3 or left<0 or left>=right or right>Int64(n): return -1
        if target<0 or target>=Int64(n) or (left<=target and target<right): return -1
    let node_cap=7*n+m+1
    let edge_cap=9*n+32*m+1
    var head=List[Int](length=node_cap,fill=0)
    var degree=List[Int](length=node_cap,fill=0)
    var first=List[Int](length=node_cap,fill=0)
    var edge_to=List[Int](length=edge_cap,fill=0)
    var edge_next=List[Int](length=edge_cap,fill=0)
    var queue=List[Int](length=node_cap,fill=0)
    var down=List[Int](length=4*n,fill=0)
    var up=List[Int](length=4*n,fill=0)
    var any_tree=List[Int](length=4*n,fill=0)
    var counts=List[Int](length=2,fill=0)
    for _ in range(n):
        _=rct_node(0,head,degree,first,counts)
    rct_build(1,0,n,down,up,any_tree,head,degree,first,edge_to,edge_next,counts)
    for i in range(m):
        let kind=Int(input[2+4*i])
        let left=Int(input[3+4*i])
        let right=Int(input[4+4*i])
        let target=Int(input[5+4*i])
        if kind==3:
            let gate=rct_node(1,head,degree,first,counts)
            rct_connect(1,0,n,left,right,kind,gate,down,up,any_tree,head,degree,edge_to,edge_next,counts)
            rct_edge(gate,target,head,degree,edge_to,edge_next,counts)
        else:
            rct_connect(1,0,n,left,right,kind,target,down,up,any_tree,head,degree,edge_to,edge_next,counts)
    var read=0
    var write=0
    var emitted=0
    for i in range(counts[0]):
        if first[i]!=0: degree[i]=1
        if degree[i]==0:
            queue[write]=i
            write+=1
    while read<write:
        let node=queue[read]
        read+=1
        if node<n: emitted+=1
        var edge=head[node]
        while edge>=0:
            let target=edge_to[edge]
            if degree[target]>0:
                degree[target]-=1
                if degree[target]==0:
                    queue[write]=target
                    write+=1
            edge=edge_next[edge]
    if emitted==n: return 1
    return 0
