from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn coins_abs(x:Int64)->Int64:return x if x>=0 else -x
fn coins_analyze(nodes:UnsafePointer[Int64,ImmutAnyOrigin],node:Int,mut moves:List[Int64])->Int64:
    if node== -1:return 1
    let l=Int(nodes[3*node+1]);let r=Int(nodes[3*node+2])
    let le=coins_analyze(nodes,l,moves);let re=coins_analyze(nodes,r,moves)
    moves[0]+=coins_abs(1-le)+coins_abs(1-re)
    return nodes[3*node]+le+re-2
@export("distribute_coins")
fn distribute_coins(nodes:UnsafePointer[Int64,ImmutAnyOrigin],node_count:c_size_t,root_index:Int64) abi("C")->Int64:
    if node_count>100:return -1
    if node_count==0:return 0 if root_index== -1 else -1
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or root_index<0 or root_index>=Int64(node_count):return -1
    let n=Int(node_count);var parents=List[Int](length=n,fill= -1);var total:Int64=0
    for i in range(n):
        let coins=nodes[3*i]
        if coins<0 or coins>100:return -1
        total+=coins
        for side in range(2):
            let child=nodes[3*i+1+side]
            if child< -1 or child>=Int64(n):return -1
            if child>=0:
                if parents[Int(child)]!= -1:return -1
                parents[Int(child)]=i
    if total!=Int64(n):return -1
    let root=Int(root_index)
    if parents[root]!= -1:return -1
    for i in range(n):if i!=root and parents[i]== -1:return -1
    var seen=List[Int](length=n,fill=0);var stack=List[Int](capacity=n);stack.append(root);var reached=0
    while len(stack)>0:
        let u=stack[len(stack)-1];stack.pop()
        if seen[u]!=0:return -1
        seen[u]=1;reached+=1
        for side in range(2):let child=nodes[3*u+1+side];if child>=0:stack.append(Int(child))
    if reached!=n:return -1
    var moves=List[Int64](length=1,fill=0);coins_analyze(nodes,root,moves)
    return moves[0]
