from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn diameter_height(nodes:UnsafePointer[Int64,ImmutAnyOrigin],count:Int,node:Int,mut seen:List[Int],mut visited:List[Int])->Int:
    if node== -1:return 0
    if node<0 or node>=count or seen[node]!=0:return -2000000000
    seen[node]=1;visited[0]+=1
    let left=nodes[3*node+1];let right=nodes[3*node+2]
    if left< -1 or right< -1 or left>=count or right>=count:return -2000000000
    let lh=diameter_height(nodes,count,Int(left),seen,visited)
    if lh== -2000000000:return lh
    let rh=diameter_height(nodes,count,Int(right),seen,visited)
    if rh== -2000000000:return rh
    return 1+ (lh if lh>rh else rh)
@export("diameter_of_binary_tree")
fn diameter_of_binary_tree(nodes:UnsafePointer[Int64,ImmutAnyOrigin],node_count:c_size_t,root_index:Int64) abi("C")->Int64:
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or node_count==0 or node_count>1023 or root_index<0 or root_index>=Int64(node_count):return -1
    let count=Int(node_count);let root=Int(root_index);let left=nodes[3*root+1];let right=nodes[3*root+2]
    if left< -1 or right< -1 or left>=Int64(count) or right>=Int64(count):return -1
    var seen=List[Int](length=count,fill=0);var visited=List[Int](length=1,fill=0);seen[root]=1;visited[0]=1
    let lh=diameter_height(nodes,count,Int(left),seen,visited)
    if lh== -2000000000:return -1
    let rh=diameter_height(nodes,count,Int(right),seen,visited)
    if rh== -2000000000 or visited[0]!=count:return -1
    return Int64(lh+rh+1)
