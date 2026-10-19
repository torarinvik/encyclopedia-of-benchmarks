from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("bst_iterator")
fn bst_iterator(nodes:UnsafePointer[Int64,ImmutAnyOrigin],node_count:c_size_t,root_index:Int64) abi("C")->Int64:
    if node_count>1023:return -1
    let n=Int(node_count)
    if n==0:return 0 if root_index== -1 else -1
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or root_index<0 or root_index>=Int64(n):return -1
    var stack=List[Int](capacity=n);var vals=List[Int64](capacity=n);var current=root_index
    while current != -1 or len(stack)>0:
        while current != -1:
            if current<0 or current>=Int64(n) or len(stack)>=n:return -1
            let ix=Int(current);let left=nodes[3*ix+1];let right=nodes[3*ix+2]
            if left< -1 or left>=Int64(n) or right< -1 or right>=Int64(n):return -1
            stack.append(ix);current=left
        let ix=stack[len(stack)-1];stack.pop()
        let value=nodes[3*ix]
        if value< -100000 or value>100000 or (len(vals)>0 and vals[len(vals)-1]>=value):return -1
        vals.append(value);current=nodes[3*ix+2]
        if len(vals)>n:return -1
    if len(vals)!=n:return -1
    var total:Int64=0
    for i in range(n):total+=Int64(i+1)*(vals[i]+100001)
    return total
