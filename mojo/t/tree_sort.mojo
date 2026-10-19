from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("tree_sort")
fn tree_sort(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if n>1024 or (n>0 and a==UnsafePointer[Int64,MutAnyOrigin]()):return
    let count=Int(n);if count==0:return
    var keys=InlineArray[Int64,1024]();var left=InlineArray[Int,1024]();var right=InlineArray[Int,1024]();var stack=InlineArray[Int,1024]()
    var root=count
    for i in range(count):
        keys[i]=a[i];left[i]=count;right[i]=count
        if root==count:root=i;continue
        var node=root
        while True:
            if keys[i]<keys[node]:
                if left[node]==count:left[node]=i;break
                node=left[node]
            else:
                if right[node]==count:right[node]=i;break
                node=right[node]
    var cur=root;var sp=0;var out=0
    while cur!=count or sp>0:
        while cur!=count:stack[sp]=cur;sp+=1;cur=left[cur]
        sp-=1;cur=stack[sp];a[out]=keys[cur];out+=1;cur=right[cur]
