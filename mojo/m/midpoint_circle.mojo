from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mc_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Int64):
    let u=UInt32(Int32(x))
    for b in range(4):out[pos+b]=UInt8((u>>(b*8))&255)
fn mc_sym(out:UnsafePointer[UInt8,MutAnyOrigin],mut pos:Int,cx:Int64,cy:Int64,x:Int64,y:Int64):
    var xs=InlineArray[Int64,8](x,-x,x,-x,y,-y,y,-y);var ys=InlineArray[Int64,8](y,y,-y,-y,x,x,-x,-x)
    for i in range(8):mc_put(out,pos,cx+xs[i]);mc_put(out,pos+4,cy+ys[i]);pos+=8
@export("midpoint_circle")
fn midpoint_circle(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3 or v[0] < -10000 or v[0]>10000 or v[1] < -10000 or v[1]>10000 or v[2]<0 or v[2]>1000:return -1
    let r=v[2];var count=1
    if r>0:
        count=8;var x=r;var y:Int64=0;var d:Int64=1-r
        while x>y:
            y+=1
            if d<=0:d+=2*y+1
            else:x-=1;d+=2*y-2*x+1
            count+=8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    if r==0:mc_put(out,0,v[0]);mc_put(out,4,v[1]);return 1
    var pos=0;var x=r;var y:Int64=0;var d:Int64=1-r;mc_sym(out,mut pos,v[0],v[1],x,y)
    while x>y:
        y+=1
        if d<=0:d+=2*y+1
        else:x-=1;d+=2*y-2*x+1
        mc_sym(out,mut pos,v[0],v[1],x,y)
    return count
