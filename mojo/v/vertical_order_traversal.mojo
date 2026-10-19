from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime MAXN=1023
comptime COLS=2047
@export("vertical_order_traversal")
fn vertical_order_traversal(nodes:UnsafePointer[Int64,ImmutAnyOrigin],count:c_size_t,root:Int64,values:UnsafePointer[Int64,MutAnyOrigin],value_cap:c_size_t,offsets:UnsafePointer[c_size_t,MutAnyOrigin],offset_cap:c_size_t,queue:UnsafePointer[c_size_t,MutAnyOrigin],queue_cap:c_size_t) abi("C")->Int64:
    if count>MAXN:return -1
    if count==0:
        if root!=-1:return -1
        if offsets==UnsafePointer[c_size_t,MutAnyOrigin]() or offset_cap<1:return -2
        offsets[0]=c_size_t(0);return 0
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or root<0 or UInt64(root)>=UInt64(count):return -1
    if values==UnsafePointer[Int64,MutAnyOrigin]() or value_cap<count or offsets==UnsafePointer[c_size_t,MutAnyOrigin]() or offset_cap<count+1 or queue==UnsafePointer[c_size_t,MutAnyOrigin]() or queue_cap<count:return -2
    var parents=InlineArray[Int,MAXN](fill=0)
    for i in range(Int(count)):
        let val=nodes[3*i];let left=nodes[3*i+1];let right=nodes[3*i+2]
        if val < -2147483648 or val > 2147483647 or left < -1 or right < -1 or (left>=0 and UInt64(left)>=UInt64(count)) or (right>=0 and UInt64(right)>=UInt64(count)):return -1
        if left>=0:parents[Int(left)]+=1
        if right>=0:parents[Int(right)]+=1
    if parents[Int(root)]!=0:return -1
    for i in range(Int(count)):
        if i!=Int(root) and parents[i]!=1:return -1
    var q=InlineArray[Int,MAXN](fill=0);var col=InlineArray[Int,MAXN](fill=0);var visited=InlineArray[Bool,MAXN](fill=False)
    var head=0;var tail=1;var minc=0;var maxc=0;q[0]=Int(root);visited[Int(root)]=True
    while head<tail:
        let u=q[head];head+=1
        let left=nodes[3*u+1];let right=nodes[3*u+2]
        if left>=0:
            let child=Int(left)
            if visited[child]:return -1
            visited[child]=True;col[child]=col[u]-1;q[tail]=child;tail+=1
            if col[child]<minc:minc=col[child]
        if right>=0:
            let child=Int(right)
            if visited[child]:return -1
            visited[child]=True;col[child]=col[u]+1;q[tail]=child;tail+=1
            if col[child]>maxc:maxc=col[child]
    if tail!=Int(count):return -1
    var head_bucket=InlineArray[Int,2047](fill=-1);var tail_bucket=InlineArray[Int,2047](fill=-1);var next=InlineArray[Int,MAXN](fill=-1)
    for i in range(Int(count)):
        let slot=col[q[i]]+MAXN
        if head_bucket[slot]<0:head_bucket[slot]=q[i]
        else:next[tail_bucket[slot]]=q[i]
        tail_bucket[slot]=q[i]
    var result=InlineArray[Int64,MAXN](fill=0);var off=InlineArray[Int,MAXN+1](fill=0);var written=0;var ncols=0
    for c in range(minc,maxc+1):
        var node=head_bucket[c+MAXN]
        while node>=0:
            result[written]=nodes[3*node];written+=1;node=next[node]
        ncols+=1;off[ncols]=written
    for i in range(Int(count)):values[i]=result[i]
    for i in range(ncols+1):offsets[i]=c_size_t(off[i])
    for i in range(Int(count)):queue[i]=c_size_t(q[i])
    return Int64(ncols)
