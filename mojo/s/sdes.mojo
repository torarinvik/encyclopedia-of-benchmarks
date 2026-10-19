from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sd_table(t:Int,i:Int)->UInt32:
    if t==0:let a=InlineArray[UInt32,8](6,3,7,4,8,5,10,9);return a[i]
    if t==1:let a=InlineArray[UInt32,10](3,5,2,7,4,10,1,9,8,6);return a[i]
    if t==2:let a=InlineArray[UInt32,8](2,6,3,1,4,8,5,7);return a[i]
    if t==3:let a=InlineArray[UInt32,8](4,1,3,5,7,2,8,6);return a[i]
    if t==4:let a=InlineArray[UInt32,8](4,1,2,3,2,3,4,1);return a[i]
    let a=InlineArray[UInt32,4](2,4,3,1);return a[i]
fn sd_perm(v:UInt32,bits:Int,t:Int,count:Int)->UInt32:
    var out:UInt32=0
    for i in range(count):out=(out<<1)|((v>>(bits-sd_table(t,i)))&1)
    return out
fn sd_rot(v:UInt32,n:Int)->UInt32:return ((v<<UInt(n))|(v>>UInt(5-n)))&31
fn sd_key(k:UInt32,r:Int)->UInt32:
    let s=sd_perm(k,10,1,10);var l=(s>>5)&31;var q=s&31;l=sd_rot(l,1);q=sd_rot(q,1)
    if r!=0:l=sd_rot(l,2);q=sd_rot(q,2)
    return sd_perm((l<<5)|q,10,0,8)
fn sd_box(which:Int,x:UInt32)->UInt32:
    let row=Int(((x&8)>>2)|(x&1));let col=Int((x>>1)&3)
    if which==0:
        let a=InlineArray[UInt32,16](1,0,3,2,3,2,1,0,0,2,1,3,3,1,3,2);return a[row*4+col]
    let b=InlineArray[UInt32,16](0,1,2,3,2,0,1,3,3,0,1,0,2,1,0,3);return b[row*4+col]
fn sd_fk(s:UInt32,k:UInt32)->UInt32:
    let l=s>>4;let r=s&15;let m=sd_perm(r,4,4,8)^k;let sub=(sd_box(0,m>>4)<<2)|sd_box(1,m&15)
    return ((l^sd_perm(sub,4,5,4))<<4)|r
fn sd_crypt(m:UInt32,k:UInt32,dec:Bool)->UInt32:
    let k1=sd_key(k,0);let k2=sd_key(k,1);var s=sd_perm(m,8,2,8)
    s=sd_fk(s,k2 if dec else k1);s=((s&15)<<4)|(s>>4);s=sd_fk(s,k1 if dec else k2)
    return sd_perm(s,8,3,8)
@export("sdes")
fn sdes(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    if a[0]<0 or a[0]>1023 or a[1]<0 or a[1]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<2:return -2
    let c=sd_crypt(UInt32(a[1]),UInt32(a[0]),False);let p=sd_crypt(c,UInt32(a[0]),True)
    o[0]=UInt8(c);o[1]=UInt8(p);return 2
