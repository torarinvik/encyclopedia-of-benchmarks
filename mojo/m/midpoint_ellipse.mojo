from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn me_count(a:Int64,b:Int64)->Int:
    if a==0:return Int(2*b+1)
    if b==0:return Int(2*a+1)
    let aa=a*a;let bb=b*b;var x:Int64=0;var y=b;var dx:Int64=0;var dy=2*aa*y
    var d1=Float64(bb)-Float64(aa*b)+0.25*Float64(aa);var count=0
    while dx<dy:
        count+=4
        if d1<0.0:x+=1;dx+=2*bb;d1+=Float64(dx+bb)
        else:x+=1;y-=1;dx+=2*bb;dy-=2*aa;d1+=Float64(dx-dy+bb)
    var d2=Float64(bb)*(Float64(x)+0.5)*(Float64(x)+0.5)+Float64(aa)*Float64(y-1)*Float64(y-1)-Float64(aa*bb)
    while y>=0:
        count+=4
        if d2>0.0:y-=1;dy-=2*aa;d2+=Float64(aa-dy)
        else:y-=1;x+=1;dx+=2*bb;dy-=2*aa;d2+=Float64(dx-dy+aa)
    return count
fn me_put(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64,y:Int64):
    let ux=UInt32(Int32(x));let uy=UInt32(Int32(y))
    for b in range(4):out[p*8+b]=UInt8((ux>>(8*b))&255);out[p*8+4+b]=UInt8((uy>>(8*b))&255)
fn me_quad(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,cx:Int64,cy:Int64,x:Int64,y:Int64):
    me_put(out,p,cx+x,cy+y);me_put(out,p+1,cx-x,cy+y);me_put(out,p+2,cx+x,cy-y);me_put(out,p+3,cx-x,cy-y)
@export("midpoint_ellipse")
fn midpoint_ellipse(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4 or v[0] < -10000 or v[0]>10000 or v[1] < -10000 or v[1]>10000 or v[2]<0 or v[2]>100 or v[3]<0 or v[3]>100:return -1
    let cx=v[0];let cy=v[1];let a=v[2];let b=v[3];let count=if a==0 and b==0:1 else:me_count(a,b)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    if a==0 and b==0:me_put(out,0,cx,cy);return 1
    if a==0:
        for i in range(count):me_put(out,i,cx,cy-b+Int64(i))
        return Int64(count)
    if b==0:
        for i in range(count):me_put(out,i,cx-a+Int64(i),cy)
        return Int64(count)
    let aa=a*a;let bb=b*b;var x:Int64=0;var y=b;var dx:Int64=0;var dy=2*aa*y;var d1=Float64(bb)-Float64(aa*b)+0.25*Float64(aa);var p=0
    while dx<dy:
        me_quad(out,p,cx,cy,x,y);p+=4
        if d1<0.0:x+=1;dx+=2*bb;d1+=Float64(dx+bb)
        else:x+=1;y-=1;dx+=2*bb;dy-=2*aa;d1+=Float64(dx-dy+bb)
    var d2=Float64(bb)*(Float64(x)+0.5)*(Float64(x)+0.5)+Float64(aa)*Float64(y-1)*Float64(y-1)-Float64(aa*bb)
    while y>=0:
        me_quad(out,p,cx,cy,x,y);p+=4
        if d2>0.0:y-=1;dy-=2*aa;d2+=Float64(aa-dy)
        else:y-=1;x+=1;dx+=2*bb;dy-=2*aa;d2+=Float64(dx-dy+aa)
    return Int64(count)
