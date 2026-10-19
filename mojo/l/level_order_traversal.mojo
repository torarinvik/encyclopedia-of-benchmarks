from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("level_order_traversal")
fn level_order_traversal(nodes:UnsafePointer[Int64,ImmutAnyOrigin],count:c_size_t,root:Int64,values:UnsafePointer[Int64,MutAnyOrigin],value_cap:c_size_t,offsets:UnsafePointer[c_size_t,MutAnyOrigin],offset_cap:c_size_t,queue:UnsafePointer[c_size_t,MutAnyOrigin],queue_cap:c_size_t) abi("C")->Int64:
    if count==0:
        if root!=-1:return -1
        if offsets==UnsafePointer[c_size_t,MutAnyOrigin]() or offset_cap<1:return -2
        offsets[0]=c_size_t(0);return 0
    if count>4096 or nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or root<0 or UInt64(root)>=UInt64(count):return -1
    if values==UnsafePointer[Int64,MutAnyOrigin]() or value_cap<count or offsets==UnsafePointer[c_size_t,MutAnyOrigin]() or offset_cap<count+1 or queue==UnsafePointer[c_size_t,MutAnyOrigin]() or queue_cap<count:return -2
    var head=0;var tail=1;var visited=0;var levels=0
    queue[0]=c_size_t(root);offsets[0]=c_size_t(0)
    while head<tail:
        let end=tail
        while head<end:
            let node=Int(queue[head]);head+=1
            values[visited]=nodes[3*node];visited+=1
            let left=nodes[3*node+1];let right=nodes[3*node+2]
            if left < -1 or right < -1 or (left>=0 and UInt64(left)>=UInt64(count)) or (right>=0 and UInt64(right)>=UInt64(count)):return -1
            if left>=0:
                if tail>=Int(queue_cap) or tail>=Int(count):return -1
                queue[tail]=c_size_t(left);tail+=1
            if right>=0:
                if tail>=Int(queue_cap) or tail>=Int(count):return -1
                queue[tail]=c_size_t(right);tail+=1
        levels+=1;offsets[levels]=c_size_t(visited)
    if visited!=Int(count):return -1
    return Int64(levels)
