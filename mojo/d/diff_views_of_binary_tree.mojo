from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
@export("diff_views_of_binary_tree")
fn diff_views_of_binary_tree(nodes:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,root:Int64,view:Int64,out:UnsafePointer[Int64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if n>1023 or view<0 or view>3:return -1
    if n==0:return 0 if root== -1 else -1
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or root<0 or root>=Int64(n):return -1
    let count=Int(n);var parents=List[Int](length=count,fill=0)
    for i in range(count):
        let value=nodes[3*i];let l=nodes[3*i+1];let r=nodes[3*i+2]
        if value< -2147483648 or value>2147483647 or l< -1 or r< -1 or l>=Int64(count) or r>=Int64(count):return -1
        if l>=0:parents[Int(l)]+=1
        if r>=0:parents[Int(r)]+=1
        if (l>=0 and parents[Int(l)]>1) or (r>=0 and parents[Int(r)]>1):return -1
    if parents[Int(root)]!=0:return -1
    for i in range(count):if i!=Int(root) and parents[i]!=1:return -1
    var queue=List[Int](capacity=count);var depth=List[Int](length=count,fill=0);var col=List[Int](length=count,fill=0);var seen=List[Int](length=count,fill=0)
    var first_depth=List[Int64](length=count,fill= -9223372036854775808);var last_depth=List[Int64](length=count,fill= -9223372036854775808)
    var first_col=List[Int64](length=2047,fill= -9223372036854775808);var last_col=List[Int64](length=2047,fill= -9223372036854775808)
    let ri=Int(root);queue.append(ri);seen[ri]=1;var head=0;var maxdepth=0;var mincol=0;var maxcol=0
    while head<len(queue):
        let u=queue[head];head+=1;let d=depth[u];let c=col[u];let value=nodes[3*u]
        if d>maxdepth:maxdepth=d
        if c<mincol:mincol=c
        if c>maxcol:maxcol=c
        if first_depth[d]== -9223372036854775808:first_depth[d]=value
        last_depth[d]=value;let ci=c+1023
        if first_col[ci]== -9223372036854775808:first_col[ci]=value
        last_col[ci]=value
        for side in range(2):
            var child=nodes[3*u+1+side]
            if child>=0:
                let v=Int(child)
                if seen[v]!=0:return -1
                seen[v]=1;depth[v]=d+1;col[v]=c+ (1 if side==1 else -1);queue.append(v)
    if len(queue)!=count:return -1
    if out==UnsafePointer[Int64,MutAnyOrigin]() or capacity<c_size_t(count):return -2
    var written=0
    if view<2:
        for d in range(maxdepth+1):
            let value=last_depth[d] if view==0 else first_depth[d]
            if value!= -9223372036854775808:out[written]=value;written+=1
    else:
        for c in range(mincol,maxcol+1):
            let value=first_col[c+1023] if view==2 else last_col[c+1023]
            if value!= -9223372036854775808:out[written]=value;written+=1
    return Int64(written)
