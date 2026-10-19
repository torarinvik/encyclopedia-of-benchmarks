from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime M=15
fn kd_base(d:Int,node:Int)->Int:return 2+d+node*(d+2)
fn nn_validate(a:UnsafePointer[Int64,ImmutAnyOrigin],d:Int,nodes:Int,node:Int,mut seen:InlineArray[Bool,M],mut count:Int)->Bool:
    if node<0:return True
    if node>=nodes or seen[node]:return False
    seen[node]=True;count+=1;let base=kd_base(d,node);let l=a[base+d];let r=a[base+d+1]
    if l< -1 or l>=nodes or r< -1 or r>=nodes or (l>=0 and l==r):return False
    return nn_validate(a,d,nodes,Int(l),seen,count) and nn_validate(a,d,nodes,Int(r),seen,count)
fn nn_search(a:UnsafePointer[Int64,ImmutAnyOrigin],d:Int,node:Int,depth:Int,q:InlineArray[Int64,3],mut best:InlineArray[Int64,3],mut bestd:Int64,mut visited:Int64):
    if node<0:return
    visited+=1;let b=kd_base(d,node);var dist:Int64=0
    for k in range(d):let delta=q[k]-a[b+k];dist+=delta*delta
    if dist<bestd:
        bestd=dist
        for k in range(d):best[k]=a[b+k]
    let axis=depth%d;let l=Int(a[b+d]);let r=Int(a[b+d+1]);let near=l if q[axis]<=a[b+axis] else r;let far=r if q[axis]<=a[b+axis] else l
    nn_search(a,d,near,depth+1,q,best,bestd,visited)
    let delta=q[axis]-a[b+axis]
    if delta*delta<bestd:nn_search(a,d,far,depth+1,q,best,bestd,visited)
@export("nearest_neighbour_search")
fn nearest_neighbour_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>80:return -1
    let d0=a[0];let nn=a[1]
    if (d0!=2 and d0!=3) or nn<1 or nn>15:return -1
    let d=Int(d0);let nodes=Int(nn)
    if n!=c_size_t(2+d+nodes*(d+2)):return -1
    var q=InlineArray[Int64,3]()
    for k in range(d):q[k]=a[2+k];if q[k]< -1000 or q[k]>1000:return -1
    for i in range(nodes):
        let b=kd_base(d,i)
        for k in range(d):if a[b+k]< -1000 or a[b+k]>1000:return -1
    var seen=InlineArray[Bool,M]();var reached=0
    if not nn_validate(a,d,nodes,0,seen,reached) or reached!=nodes:return -1
    var best=InlineArray[Int64,3]();var bestd:Int64=9223372036854775807;var visited:Int64=0
    nn_search(a,d,0,0,q,best,bestd,visited)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<48:return -2
    var result=InlineArray[Int64,6]();result[0]=d0;result[1]=best[0];result[2]=best[1];result[3]=best[2];result[4]=bestd;result[5]=visited
    for i in range(6):let bits=UInt64(result[i]);for b in range(8):o[i*8+b]=UInt8((bits>>(8*b))&255)
    return 48
