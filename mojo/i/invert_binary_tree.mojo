from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn invtree_write(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):out[at+b]=UInt8((bits>>(8*b))&255)

@export("invert_binary_tree")
fn invert_binary_tree(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                      output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or (Int(length)-1)%3!=0 or length>3070:return -1
    let n=(Int(length)-1)//3;let root=input[0]
    if n==0:return 0 if root== -1 else -1
    if root<0 or root>=n:return -1
    var seen=InlineArray[Bool,1023](fill=False);var stack=InlineArray[Int32,1023](fill=0);var depths=InlineArray[Int32,1023](fill=0)
    var top=1;stack[0]=Int32(root);depths[0]=1;seen[Int(root)]=True;var count=0
    while top>0:
        top-=1;let node=Int(stack[top]);let depth=Int(depths[top]);count+=1
        if depth>512:return -1
        let base=1+3*node;let value=input[base];let left=input[base+1];let right=input[base+2]
        if value< -2147483648 or value>2147483647 or left< -1 or right< -1 or left>=n or right>=n:return -1
        if left>=0:
            if seen[Int(left)]:return -1
            seen[Int(left)]=True;stack[top]=Int32(left);depths[top]=Int32(depth+1);top+=1
        if right>=0:
            if seen[Int(right)]:return -1
            seen[Int(right)]=True;stack[top]=Int32(right);depths[top]=Int32(depth+1);top+=1
    if count!=n:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(n*24):return -2
    for node in range(n):
        let base=1+3*node
        invtree_write(output,node*24,input[base]);invtree_write(output,node*24+8,input[base+2]);invtree_write(output,node*24+16,input[base+1])
    return Int64(n)
