from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn bst(nodes:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,node:Int64,haslo:Bool,lo:Int64,hashi:Bool,hi:Int64)->Int64:
    if node == -1:return 1
    if node<0 or node>=n:return -1
    let i=Int(node);let value=nodes[3*i];let left=nodes[3*i+1];let right=nodes[3*i+2]
    if value < -2147483648 or value>2147483647 or left < -1 or left>=n or right < -1 or right>=n:return -1
    if (haslo and value<=lo) or (hashi and value>=hi):return 0
    let a=bst(nodes,n,left,haslo,lo,True,value)
    if a<=0:return a
    return bst(nodes,n,right,True,value,hashi,hi)
@export("validate_bst")
fn validate_bst(nodes:UnsafePointer[Int64,ImmutAnyOrigin],count:c_size_t,root:Int64) abi("C")->Int64:
    if count>1023:return -1
    if count==0:return 1 if root == -1 else -1
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or root<0 or root>=Int64(count):return -1
    return bst(nodes,Int(count),root,False,0,False,0)
