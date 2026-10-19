from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime FLAT_MAX_NODES = 1023

fn flat_write64(out: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits=UInt64(value)
    for b in range(8): out[offset+b]=UInt8((bits>>(8*b))&255)

@export("flatten_binarytree_to_linkedlist")
fn flatten_binarytree_to_linkedlist(input: UnsafePointer[Int64,ImmutAnyOrigin], length:c_size_t,
                                    output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>3070 or (Int(length)-1)%3!=0:return -1
    let n=(Int(length)-1)//3
    let root=input[0]
    if n==0:
        if root != -1:return -1
        return 0
    if root<0 or root>=n:return -1
    var seen=InlineArray[Bool,1023](fill=False)
    var order=InlineArray[Int32,1023](fill=0)
    var stack=InlineArray[Int32,1023](fill=0)
    var depths=InlineArray[Int32,1023](fill=0)
    var top=1; stack[0]=Int32(root); depths[0]=1; seen[Int(root)]=True
    var count=0
    while top>0:
        top-=1
        let node=Int(stack[top]); let depth=Int(depths[top])
        if node<0 or node>=n or depth>512:return -1
        order[count]=Int32(node); count+=1
        let base=1+3*node
        let value=input[base]; let left=input[base+1]; let right=input[base+2]
        if value< -2147483648 or value>2147483647 or left< -1 or right< -1 or left>=n or right>=n:return -1
        if right>=0:
            if seen[Int(right)]:return -1
            seen[Int(right)]=True; stack[top]=Int32(right); depths[top]=Int32(depth+1); top+=1
        if left>=0:
            if seen[Int(left)]:return -1
            seen[Int(left)]=True; stack[top]=Int32(left); depths[top]=Int32(depth+1); top+=1
    if count!=n:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(24*n):return -2
    var next=InlineArray[Int32,1023](fill=-1)
    for i in range(count-1):next[Int(order[i])]=order[i+1]
    for node in range(n):
        flat_write64(output,24*node,input[1+3*node])
        flat_write64(output,24*node+8,-1)
        flat_write64(output,24*node+16,Int64(next[node]))
    return Int64(n)
