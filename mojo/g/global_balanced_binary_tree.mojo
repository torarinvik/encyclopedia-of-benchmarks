from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime GBST_MAX_N = 64
comptime GBST_MAX_PARSEABLE_LENGTH = 65

fn gbst_build_interval(lo:Int,hi:Int,inout path:InlineArray[Int,64],inout prefix:InlineArray[Int,65],inout gbst_parent:InlineArray[Int,64],inout left_child:InlineArray[Int,64],inout right_child:InlineArray[Int,64],inout local_size:InlineArray[Int,64])->Int:
    let total_weight=prefix[hi]-prefix[lo]
    var low=lo;var high=hi
    while high-low>1:
        let middle=(low+high)/2
        if 2*(prefix[middle]-prefix[lo])<=total_weight:low=middle
        else:high=middle
    let pivot=low;let node=path[pivot];local_size[node]=hi-lo
    if lo<pivot:
        let child=gbst_build_interval(lo,pivot,path,prefix,gbst_parent,left_child,right_child,local_size)
        left_child[node]=child;gbst_parent[child]=node
    if pivot+1<hi:
        let child=gbst_build_interval(pivot+1,hi,path,prefix,gbst_parent,left_child,right_child,local_size)
        right_child[node]=child;gbst_parent[child]=node
    return node

@export("global_balanced_binary_tree")
fn global_balanced_binary_tree(a:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>c_size_t(GBST_MAX_PARSEABLE_LENGTH):return -1
    let n_value=a[0]
    if n_value<1 or n_value>Int64(GBST_MAX_N):return -1
    if length!=c_size_t(n_value):return -1
    let n=Int(n_value)

    var parent=InlineArray[Int,64](fill=-1)
    var subtree_size=InlineArray[Int,64](fill=1)
    var heavy_child=InlineArray[Int,64](fill=-1)
    var gbst_parent=InlineArray[Int,64](fill=-1)
    var left_child=InlineArray[Int,64](fill=-1)
    var right_child=InlineArray[Int,64](fill=-1)
    var local_size=InlineArray[Int,64](fill=0)
    var path=InlineArray[Int,64](fill=0)
    var prefix=InlineArray[Int,65](fill=0)

    for vertex in range(1,n):
        let p=a[vertex]
        if p<0 or p>=Int64(vertex):return -1
        parent[vertex]=Int(p)
    for offset in range(n-1):
        let vertex=n-1-offset
        subtree_size[parent[vertex]]+=subtree_size[vertex]
    for vertex in range(1,n):
        let p=parent[vertex];let current=heavy_child[p]
        if current<0 or subtree_size[vertex]>subtree_size[current]:heavy_child[p]=vertex

    for head in range(n):
        if head>0 and heavy_child[parent[head]]==head:continue
        var path_length=0;var vertex=head;prefix[0]=0
        while vertex<n:
            let child=heavy_child[vertex]
            let weight=subtree_size[vertex]-(subtree_size[child] if child>=0 else 0)
            path[path_length]=vertex
            prefix[path_length+1]=prefix[path_length]+weight
            path_length+=1
            if child<0:break
            vertex=child
        let root=gbst_build_interval(0,path_length,path,prefix,gbst_parent,left_child,right_child,local_size)
        gbst_parent[root]= -1 if head==0 else parent[head]

    var checksum:Int64=0
    for vertex in range(n):
        let record=Int64(gbst_parent[vertex]+1)+Int64(65)*Int64(left_child[vertex]+1)+Int64(4225)*Int64(right_child[vertex]+1)+Int64(274625)*Int64(local_size[vertex])
        checksum+=(Int64(vertex)+1)*record
    return checksum
