from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("even_tree")
fn even_tree(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>200:return -9223372036854775808
    let nn=input[0];let mm=input[1]
    if nn<2 or nn>100 or nn%2!=0 or mm!=nn-1 or length!=c_size_t(2+2*mm):return -9223372036854775808
    let n=Int(nn);var adj=List[List[Int]](capacity=n)
    for v in range(n):adj.append(List[Int](capacity=n))
    var seen_edges=InlineArray[Int64,10000](fill=0)
    for i in range(Int(mm)):
        let u=input[2+2*i];let v=input[3+2*i]
        if u<1 or u>nn or v<1 or v>nn or u==v:return -9223372036854775808
        let a=Int(u-1);let b=Int(v-1)
        if seen_edges[a*100+b]!=0 or seen_edges[b*100+a]!=0:return -9223372036854775808
        seen_edges[a*100+b]=1;seen_edges[b*100+a]=1;adj[a].append(b);adj[b].append(a)
    var parent=InlineArray[Int64,100](fill= -2);var order=List[Int](capacity=n);var stack=List[Int](capacity=n)
    parent[0]= -1;stack.append(0)
    while len(stack)>0:
        let u=stack[len(stack)-1];stack.pop();order.append(u)
        for i in range(len(adj[u])):
            let v=adj[u][i]
            if Int64(v)==parent[u]:continue
            if parent[v]!= -2:return -9223372036854775808
            parent[v]=u;stack.append(v)
    if len(order)!=n:return -9223372036854775808
    var sizes=InlineArray[Int64,100](fill=1);var cuts:Int64=0
    for ix in range(n):
        let u=Int(order[n-1-ix])
        if sizes[u]%2==0:cuts+=1
        if parent[u]>=0:sizes[Int(parent[u])]+=sizes[u]
    return cuts-1
