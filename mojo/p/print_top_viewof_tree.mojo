from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("print_top_viewof_tree")
fn print_top_viewof_tree(nodes:UnsafePointer[Int64,ImmutAnyOrigin],count:c_size_t,root:Int64,values:UnsafePointer[Int64,MutAnyOrigin],value_cap:c_size_t,offsets:UnsafePointer[c_size_t,MutAnyOrigin],offset_cap:c_size_t,queue:UnsafePointer[c_size_t,MutAnyOrigin],queue_cap:c_size_t) abi("C")->Int64:
    if count>1023:return -1
    if count==0:
        if root!= -1:return -1
        if offsets==UnsafePointer[c_size_t,MutAnyOrigin]() or offset_cap<1:return -2
        offsets[0]=c_size_t(0);return 0
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or root<0 or UInt64(root)>=UInt64(count):return -1
    let size=Int(count)
    var parents=InlineArray[Int,1023](fill=0)
    for i in range(size):
        let value=nodes[3*i];let left=nodes[3*i+1];let right=nodes[3*i+2]
        if value< -2147483648 or value>2147483647:return -1
        if left< -1 or right< -1 or left>=Int64(count) or right>=Int64(count):return -1
        if left>=0:parents[Int(left)]+=1
        if right>=0:parents[Int(right)]+=1
    for i in range(size):if (i==Int(root) and parents[i]!=0) or (i!=Int(root) and parents[i]!=1):return -1
    var seen=InlineArray[Bool,1023](fill=False);var q=InlineArray[Int,1023](fill=0);var col=InlineArray[Int,1023](fill=0);var head=0;var tail=1;q[0]=Int(root);seen[Int(root)]=True
    var visible=InlineArray[Bool,2047](fill=False);var outvals=InlineArray[Int64,1023](fill=0);var outcount=0
    while head<tail:
        let node=q[head];let c=col[head];head+=1
        let key=c+1023
        if not visible[key]:visible[key]=True;outvals[outcount]=nodes[3*node];outcount+=1
        let children=InlineArray[Int64,2](nodes[3*node+1],nodes[3*node+2])
        for side in range(2):
            let child=children[side]
            if child<0:continue
            if seen[Int(child)]:return -1
            seen[Int(child)]=True;q[tail]=Int(child);col[tail]=c+(-1 if side==0 else 1);tail+=1
    if tail!=size:return -1
    if values==UnsafePointer[Int64,MutAnyOrigin]() or value_cap<c_size_t(outcount) or offsets==UnsafePointer[c_size_t,MutAnyOrigin]() or offset_cap<c_size_t(outcount+1) or queue==UnsafePointer[c_size_t,MutAnyOrigin]() or queue_cap<count:return -2
    for i in range(outcount):values[i]=outvals[i];offsets[i]=c_size_t(i)
    offsets[outcount]=c_size_t(outcount)
    for i in range(size):queue[i]=c_size_t(q[i])
    return Int64(outcount)
