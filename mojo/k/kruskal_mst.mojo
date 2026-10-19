from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime ME=2016
fn km_sift(mut a:InlineArray[Int64,ME],start:Int,end:Int):
    var root=start
    while root<end//2:
        var child=root*2+1
        if child+1<end and a[child]<a[child+1]:child+=1
        if a[root]>=a[child]:break
        let t=a[root];a[root]=a[child];a[child]=t;root=child
fn km_find(mut p:InlineArray[Int64,64],x0:Int)->Int:
    var x=x0
    while p[x]!=x:x=Int(p[x])
    var q=x0
    while p[q]!=q:let z=Int(p[q]);p[q]=x;q=z
    return x
fn km_hashbyte(h0:UInt64,b:UInt64)->UInt64:return (h0^b)*1099511628211
@export("kruskal_mst")
fn kruskal_mst(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>6051:return -1
    let nv=a[0];let ne=a[1]
    if nv<1 or nv>64 or ne<0 or ne>2016 or n!=c_size_t(2+3*ne):return -1
    if (nv==1 and ne!=0) or (nv>1 and (ne<nv-1 or ne>nv*(nv-1)//2)):return -1
    var keys=InlineArray[Int64,ME]();var count=Int(ne)
    for i in range(count):
        var u=a[2+3*i];var v=a[3+3*i];let w=a[4+3*i]
        if u<0 or u>=nv or v<0 or v>=nv or u==v or w< -1000000 or w>1000000:return -1
        if u>v:let t=u;u=v;v=t
        keys[i]=(w+1000000)*4096+u*64+v
        for j in range(i):
            if keys[j]//4096==keys[i]//4096:return -1
            let ju=(keys[j]%4096)//64;let jv=keys[j]%64
            if ju==u and jv==v:return -1
    for i in range(count//2-1,-1,-1):km_sift(keys,i,count)
    for end in range(count-1,0,-1):let t=keys[0];keys[0]=keys[end];keys[end]=t;km_sift(keys,0,end)
    var parent=InlineArray[Int64,64]();var rank=InlineArray[Int64,64]();for i in range(Int(nv)):parent[i]=i
    var eu=InlineArray[Int64,64]();var ev=InlineArray[Int64,64]();var ew=InlineArray[Int64,64]();var used=0;var total:Int64=0
    for i in range(count):
        let key=keys[i];let u=Int((key%4096)//64);let v=Int(key%64);let w=key//4096-1000000;let ru=km_find(parent,u);let rv=km_find(parent,v)
        if ru!=rv:
            if rank[ru]<rank[rv]:parent[ru]=rv
            elif rank[ru]>rank[rv]:parent[rv]=ru
            else:parent[rv]=ru;rank[ru]+=1
            eu[used]=u;ev[used]=v;ew[used]=w;used+=1;total+=w
    if used!=nv-1:return -1
    var h:UInt64=14695981039346656037
    h=km_hashbyte(h,UInt64(nv)&255);h=km_hashbyte(h,(UInt64(nv)>>8)&255)
    h=km_hashbyte(h,UInt64(used)&255);h=km_hashbyte(h,(UInt64(used)>>8)&255)
    for i in range(used):
        let u=UInt64(eu[i]);let v=UInt64(ev[i]);let w=UInt32(Int32(ew[i]))
        h=km_hashbyte(h,u&255);h=km_hashbyte(h,(u>>8)&255);h=km_hashbyte(h,v&255);h=km_hashbyte(h,(v>>8)&255)
        for b in range(4):h=km_hashbyte(h,(UInt64(w)>>(8*b))&255)
    let bits=UInt64(total)
    for b in range(8):h=km_hashbyte(h,(bits>>(8*b))&255)
    return Int64(h&0x7fffffffffffffff)
