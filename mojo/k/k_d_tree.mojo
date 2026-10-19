from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import isfinite, sqrt
fn kdt_build(points:InlineArray[Float64,45],dim:Int,indices:InlineArray[Int,15],count:Int,axis:Int,inout left:InlineArray[Int,15],inout right:InlineArray[Int,15])->Int:
    if count==0:return -1
    var sorted=indices
    for i in range(1,count):
        let value=sorted[i];var j=i-1
        while j>=0 and points[sorted[j]*dim+axis]>points[value*dim+axis]:sorted[j+1]=sorted[j];j-=1
        sorted[j+1]=value
    let mid=(count-1)//2;let root=sorted[mid]
    var lo=InlineArray[Int,15](fill=0);var hi=InlineArray[Int,15](fill=0)
    for i in range(mid):lo[i]=sorted[i]
    for i in range(count-mid-1):hi[i]=sorted[mid+1+i]
    left[root]=kdt_build(points,dim,lo,mid,(axis+1)%dim,left,right)
    right[root]=kdt_build(points,dim,hi,count-mid-1,(axis+1)%dim,left,right)
    return root
fn kdt_search(node:Int,axis:Int,dim:Int,points:InlineArray[Float64,45],query:InlineArray[Float64,3],left:InlineArray[Int,15],right:InlineArray[Int,15],inout best:Int,inout bestdist:Float64):
    if node<0:return
    var ds=0.0
    for j in range(dim):let d=query[j]-points[node*dim+j];ds+=d*d
    if ds<bestdist:bestdist=ds;best=node
    let split=query[axis]-points[node*dim+axis]
    let near=left[node] if split<=0.0 else right[node];let far=right[node] if split<=0.0 else left[node]
    kdt_search(near,(axis+1)%dim,dim,points,query,left,right,best,bestdist)
    if split*split<=bestdist:kdt_search(far,(axis+1)%dim,dim,points,query,left,right,best,bestdist)
@export("k_d_tree")
fn k_d_tree(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<2 or n>51:return -1
    if not isfinite(a[0]) or not isfinite(a[1]) or Float64(Int(a[0]))!=a[0] or Float64(Int(a[1]))!=a[1]:return -1
    let dim=Int(a[0]);let count=Int(a[1])
    if (dim!=2 and dim!=3) or count<1 or count>15 or n!=c_size_t(2+dim*(count+1)):return -1
    var points=InlineArray[Float64,45](fill=0.0);var query=InlineArray[Float64,3](fill=0.0)
    for j in range(dim):
        query[j]=a[2+j]
        if not isfinite(query[j]) or query[j]< -1000.0 or query[j]>1000.0 or Float64(Int64(query[j]))!=query[j]:return -1
    for i in range(count):for j in range(dim):
        let x=a[2+dim+i*dim+j]
        if not isfinite(x) or x< -1000.0 or x>1000.0 or Float64(Int64(x))!=x:return -1
        points[i*dim+j]=x
        for prev in range(i):if points[prev*dim+j]==x:return -1
    var distances=InlineArray[Float64,15](fill=0.0)
    for i in range(count):
        for j in range(dim):let d=query[j]-points[i*dim+j];distances[i]+=d*d
        for prev in range(i):if distances[prev]==distances[i]:return -1
    var indices=InlineArray[Int,15](fill=0);var left=InlineArray[Int,15](fill=-1);var right=InlineArray[Int,15](fill=-1)
    for i in range(count):indices[i]=i
    let root=kdt_build(points,dim,indices,count,0,left,right);var best=-1;var bestdist=1.0e300
    kdt_search(root,0,dim,points,query,left,right,best,bestdist)
    let required=dim+1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(required):return -2
    o[0]=sqrt(bestdist)
    for j in range(dim):o[j+1]=points[best*dim+j]
    return Int64(required)
