from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime MAX_N=1023
fn uni(nodes:UnsafePointer[Int64,ImmutAnyOrigin],count:Int,node:Int64)->Int64:
    if node == -1:return 1
    if node<0 or node>=count:return -1
    let ix=Int(node);let value=nodes[3*ix];let left=nodes[3*ix+1];let right=nodes[3*ix+2]
    if left < -1 or left>=count or right < -1 or right>=count:return -1
    if (left>=0 and nodes[3*Int(left)]!=value) or (right>=0 and nodes[3*Int(right)]!=value):return 0
    let a=uni(nodes,count,left)
    if a<=0:return a
    return uni(nodes,count,right)
@export("univalued_binary_tree")
fn univalued_binary_tree(nodes:UnsafePointer[Int64,ImmutAnyOrigin],count:c_size_t,root:Int64) abi("C")->Int64:
    if count>c_size_t(MAX_N):return -1
    if count==0:return 1 if root == -1 else -1
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or root<0 or root>=Int64(count):return -1
    return uni(nodes,Int(count),root)
