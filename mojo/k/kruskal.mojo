from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime E=4096
fn kr_sift(mut a:InlineArray[Int64,E],start:Int,end:Int):
    var root=start
    while root<end//2:
        var child=root*2+1
        if child+1<end and a[child]<a[child+1]:child+=1
        if a[root]>=a[child]:break
        let t=a[root];a[root]=a[child];a[child]=t;root=child
fn kr_find(mut p:InlineArray[Int64,64],x0:Int)->Int:
    var x=x0
    while p[x]!=x:x=Int(p[x])
    var q=x0
    while p[q]!=q:let z=Int(p[q]);p[q]=x;q=z
    return x
@export("kruskal")
fn kruskal(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>12290:return -2
    let nv=a[0];let ne=a[1]
    if nv<0 or nv>64 or ne<0 or ne>4096 or n!=c_size_t(2+3*ne):return -2
    var keys=InlineArray[Int64,E]();var count=0
    for i in range(Int(ne)):
        var u=a[2+3*i];var v=a[3+3*i];let w=a[4+3*i]
        if u<0 or u>=nv or v<0 or v>=nv or w<0 or w>2147483647:return -2
        if u==v:continue
        if u>v:let t=u;u=v;v=t
        keys[count]=(w*64+u)*64+v;count+=1
    for i in range(count//2-1,-1,-1):kr_sift(keys,i,count)
    for end in range(count-1,0,-1):let t=keys[0];keys[0]=keys[end];keys[end]=t;kr_sift(keys,0,end)
    var parent=InlineArray[Int64,64]();var rank=InlineArray[Int64,64]();for i in range(Int(nv)):parent[i]=i
    var total:Int64=0;var used=0
    for i in range(count):
        let key=keys[i];let u=Int((key//64)%64);let v=Int(key%64);let w=key//4096
        var ru=kr_find(parent,u);var rv=kr_find(parent,v)
        if ru!=rv:
            if rank[ru]<rank[rv]:parent[ru]=rv
            elif rank[ru]>rank[rv]:parent[rv]=ru
            else:parent[rv]=ru;rank[ru]+=1
            total+=w;used+=1
    if nv<=1:return 0
    if used!=nv-1:return -1
    return total
