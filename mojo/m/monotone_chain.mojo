from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mc_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):o[p+b]=UInt8((u>>(8*b))&255)
@export("monotone_chain")
fn monotone_chain(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>130 or v[0]<0 or v[0]>64 or Int(n)!=1+2*Int(v[0]):return -1
    let count=Int(v[0]);var xs=InlineArray[Int32,64](fill=0);var ys=InlineArray[Int32,64](fill=0)
    for i in range(count):let x=v[1+2*i];let y=v[2+2*i];if x < -1000000 or x>1000000 or y < -1000000 or y>1000000:return -1;xs[i]=Int32(x);ys[i]=Int32(y)
    for i in range(1,count):let x=xs[i];let y=ys[i];var j=i;while j>0 and (xs[j-1]>x or (xs[j-1]==x and ys[j-1]>y)):xs[j]=xs[j-1];ys[j]=ys[j-1];j-=1;xs[j]=x;ys[j]=y
    var ux=InlineArray[Int32,64](fill=0);var uy=InlineArray[Int32,64](fill=0);var u=0
    for i in range(count):if u==0 or xs[i]!=ux[u-1] or ys[i]!=uy[u-1]:ux[u]=xs[i];uy[u]=ys[i];u+=1
    var hx=InlineArray[Int32,128](fill=0);var hy=InlineArray[Int32,128](fill=0);var h=0
    if u==1:hx[0]=ux[0];hy[0]=uy[0];h=1
    elif u>1:
        for i in range(u):
            while h>=2 and (Int64(hx[h-1]-hx[h-2])*Int64(uy[i]-hy[h-2])-Int64(hy[h-1]-hy[h-2])*Int64(ux[i]-hx[h-2]))<=0:h-=1
            hx[h]=ux[i];hy[h]=uy[i];h+=1
        let lower=h
        for z in range(u-1):
            let i=u-2-z
            while h>lower and (Int64(hx[h-1]-hx[h-2])*Int64(uy[i]-hy[h-2])-Int64(hy[h-1]-hy[h-2])*Int64(ux[i]-hx[h-2]))<=0:h-=1
            hx[h]=ux[i];hy[h]=uy[i];h+=1
        h-=1
    let bytes=h*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(h):mc_put(o,8*i,hx[i]);mc_put(o,8*i+4,hy[i])
    return Int64(bytes)
