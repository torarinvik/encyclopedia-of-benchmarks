from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime MAXP=128
fn kd_build(mut px:InlineArray[Int64,MAXP],mut py:InlineArray[Int64,MAXP],mut x:InlineArray[Int64,MAXP],mut y:InlineArray[Int64,MAXP],mut ax:InlineArray[Int64,MAXP],mut left:InlineArray[Int64,MAXP],mut right:InlineArray[Int64,MAXP],lo:Int,hi:Int,depth:Int,mut used:Int)->Int:
    if lo>=hi:return -1
    let axis=depth%2
    for i in range(lo+1,hi):
        let vx=px[i];let vy=py[i];var j=i
        while j>lo and (if axis==0 then px[j-1]>vx else py[j-1]>vy):px[j]=px[j-1];py[j]=py[j-1];j-=1
        px[j]=vx;py[j]=vy
    let m=lo+(hi-lo)//2;let idx=used;used+=1;x[idx]=px[m];y[idx]=py[m];ax[idx]=axis;left[idx]=-1;right[idx]=-1
    left[idx]=kd_build(px,py,x,y,ax,left,right,lo,m,depth+1,used)
    right[idx]=kd_build(px,py,x,y,ax,left,right,m+1,hi,depth+1,used)
    return idx
fn kd_insert(mut x:InlineArray[Int64,MAXP],mut y:InlineArray[Int64,MAXP],mut ax:InlineArray[Int64,MAXP],mut left:InlineArray[Int64,MAXP],mut right:InlineArray[Int64,MAXP],mut count:Int,root:Int,px:Int64,py:Int64,depth:Int)->Int:
    if root<0:
        let idx=count;count+=1;x[idx]=px;y[idx]=py;ax[idx]=depth%2;left[idx]=-1;right[idx]=-1;return idx
    let axis=Int(ax[root])
    if (px<x[root] if axis==0 else py<y[root]):left[root]=kd_insert(x,y,ax,left,right,count,Int(left[root]),px,py,depth+1)
    else:right[root]=kd_insert(x,y,ax,left,right,count,Int(right[root]),px,py,depth+1)
    return root
fn kd_search(x:InlineArray[Int64,MAXP],y:InlineArray[Int64,MAXP],ax:InlineArray[Int64,MAXP],left:InlineArray[Int64,MAXP],right:InlineArray[Int64,MAXP],root:Int,px:Int64,py:Int64)->Bool:
    if root<0:return False
    if x[root]==px and y[root]==py:return True
    let goleft=(px<x[root] if ax[root]==0 else py<y[root])
    return kd_search(x,y,ax,left,right,Int(left[root]) if goleft else Int(right[root]),px,py)
fn kd_near(x:InlineArray[Int64,MAXP],y:InlineArray[Int64,MAXP],ax:InlineArray[Int64,MAXP],left:InlineArray[Int64,MAXP],right:InlineArray[Int64,MAXP],root:Int,px:Int64,py:Int64,mut best:Int)->Int:
    if root<0:return best
    if x[root]==px and y[root]==py:return root
    let dx=x[root]-px;let dy=y[root]-py;let d=dx*dx+dy*dy
    let bx=x[best]-px;let by=y[best]-py;let bd=bx*bx+by*by
    if d<bd:best=root
    let other=dy*dy if ax[root]==0 else dx*dx
    let goleft=(px<x[root] if ax[root]==0 else py<y[root])
    let first=Int(left[root]) if goleft else Int(right[root]);let second=Int(right[root]) if goleft else Int(left[root])
    best=kd_near(x,y,ax,left,right,first,px,py,best)
    let qx=x[best]-px;let qy=y[best]-py
    if other<qx*qx+qy*qy:best=kd_near(x,y,ax,left,right,second,px,py,best)
    return best
@export("kdtree_benchmark")
fn kdtree_benchmark(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>899:return -1
    let ni=a[0]
    if ni<0 or ni>64:return -1
    let oi=1+2*Int(ni)
    if oi>=Int(n) or a[oi]<0 or a[oi]>256:return -1
    let ops=Int(a[oi]);if n!=c_size_t(oi+1+3*ops) or n>898:return -1
    var px=InlineArray[Int64,MAXP]();var py=InlineArray[Int64,MAXP]()
    for i in range(Int(ni)):
        px[i]=a[1+2*i];py[i]=a[2+2*i]
        if px[i]<-1000 or px[i]>1000 or py[i]<-1000 or py[i]>1000:return -1
        for j in range(i):if px[i]==px[j] or py[i]==py[j]:return -1
    var x=InlineArray[Int64,MAXP]();var y=InlineArray[Int64,MAXP]();var ax=InlineArray[Int64,MAXP]();var left=InlineArray[Int64,MAXP]();var right=InlineArray[Int64,MAXP]();var count=0
    let root=kd_build(px,py,x,y,ax,left,right,0,Int(ni),0,count);var root0=root;var checksum:Int64=0
    for op in range(ops):
        let pos=oi+1+3*op;let code=a[pos];let u=a[pos+1];let v=a[pos+2]
        if code==0 or code==1 or code==4:
            if u<-1000 or u>1000 or v<-1000 or v>1000:return -1
            if code==0:
                if count>=MAXP:return -1
                for i in range(count):if x[i]==u or y[i]==v:return -1
                root0=kd_insert(x,y,ax,left,right,count,root0,u,v,0)
                continue
            elif code==1:checksum+=(op+1)*((1 if kd_search(x,y,ax,left,right,root0,u,v) else 0)+1001)
            else:
                if root0<0:return -1
                let best=kd_near(x,y,ax,left,right,root0,u,v,root0);let dx=x[best]-u;let dy=y[best]-v;checksum+=(op+1)*(dx*dx+dy*dy+1001)
        elif code==2 or code==3:
            if u<0 or u>1 or v!=0 or root0<0:return -1
            var low=x[0] if u==0 else y[0];var high=low
            for i in range(1,count):let q=x[i] if u==0 else y[i];low=min(low,q);high=max(high,q)
            checksum+=(op+1)*((if code==2 then low else high)+1001)
        else:return -1
    return checksum
