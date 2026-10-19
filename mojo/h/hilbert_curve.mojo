from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn hc_reverse(inout p:InlineArray[Int64,8192],off:Int,count:Int):
    for i in range(count//2):
        let a=off+2*i;let b=off+2*(count-1-i);let x=p[a];let y=p[a+1];p[a]=p[b];p[a+1]=p[b+1];p[b]=x;p[b+1]=y
fn hc_curve(x:Int64,y:Int64,side:Int64,level:Int,angle:Int,inout p:InlineArray[Int64,8192],off:Int)->Int:
    let q=side//4;var px=InlineArray[Int64,4](fill=0);var py=InlineArray[Int64,4](fill=0)
    px[0]=x+q;py[0]=y+q;px[1]=x-q;py[1]=y+q;px[2]=x-q;py[2]=y-q;px[3]=x+q;py[3]=y-q
    var rx=InlineArray[Int64,4](fill=0);var ry=InlineArray[Int64,4](fill=0);let a=((angle%4)+4)%4
    for i in range(4):rx[i]=px[(i+a)%4];ry[i]=py[(i+a)%4]
    if level==1:
        for i in range(4):p[off+2*i]=rx[i];p[off+2*i+1]=ry[i]
        return 4
    let h=side//2;let n=hc_curve(rx[0],ry[0],h,level-1,angle+1,p,off);hc_reverse(p,off,n)
    let n1=hc_curve(rx[1],ry[1],h,level-1,angle,p,off+2*n)
    let n2=hc_curve(rx[2],ry[2],h,level-1,angle,p,off+2*(n+n1))
    let n3=hc_curve(rx[3],ry[3],h,level-1,angle-1,p,off+2*(n+n1+n2));hc_reverse(p,off+2*(n+n1+n2),n3)
    return n+n1+n2+n3
@export("hilbert_curve")
fn hilbert_curve(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or a[0]<1 or a[0]>6 or a[1]<0 or a[1]>3:return -1
    let count=1<<(2*Int(a[0]));let bytes=count*16
    if cap<c_size_t(bytes) or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    var p=InlineArray[Int64,8192](fill=0);_=hc_curve(0,0,Int64(1)<<(Int(a[0])+1),Int(a[0]),Int(a[1]),p,0)
    for i in range(2*count):
        let u=bitcast[UInt64](p[i])
        for b in range(8):o[i*8+b]=UInt8((u>>UInt(8*b))&255)
    return Int64(bytes)
