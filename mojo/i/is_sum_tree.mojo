from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn ist_sum(nodes:InlineArray[Int64,1200],index:Int64)->Int64:
    if index<0:return 0
    let base=Int(index)*3
    return nodes[base]+ist_sum(nodes,nodes[base+1])+ist_sum(nodes,nodes[base+2])
fn ist_check(nodes:InlineArray[Int64,1200],index:Int64)->Bool:
    let base=Int(index)*3;let value=nodes[base];let left=nodes[base+1];let right=nodes[base+2]
    if left== -1 and right== -1:return True
    return value==ist_sum(nodes,left)+ist_sum(nodes,right) and (left== -1 or ist_check(nodes,left)) and (right== -1 or ist_check(nodes,right))

@export("is_sum_tree")
fn is_sum_tree(nodes:UnsafePointer[Int64,ImmutAnyOrigin],count:c_size_t,root:Int64) abi("C")->Int64:
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or count==0 or count>400 or root<0 or root>=Int64(count):return -9000000000000000000
    var copied=InlineArray[Int64,1200](fill=0);var seen=InlineArray[Bool,400](fill=False);var stack=InlineArray[Int32,800](fill=0);var top=1;stack[0]=Int32(root)
    while top>0:
        top-=1;let idx=Int(stack[top])
        if idx<0 or idx>=Int(count) or seen[idx]:return -9000000000000000000
        seen[idx]=True
        let base=3*idx;let value=nodes[base];let left=nodes[base+1];let right=nodes[base+2]
        if value< -1000000000 or value>1000000000 or left< -1 or right< -1 or left>=Int64(count) or right>=Int64(count):return -9000000000000000000
        copied[base]=value;copied[base+1]=left;copied[base+2]=right
        if left>=0:stack[top]=Int32(left);top+=1
        if right>=0:stack[top]=Int32(right);top+=1
    return 1 if ist_check(copied,root) else 0
