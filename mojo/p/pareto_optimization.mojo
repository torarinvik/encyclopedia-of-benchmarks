from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn po_feed(h0:UInt64,x:Int64)->UInt64:
    var h=h0;let u=UInt64(x)
    for b in range(8):h=(h^UInt64((u>>(8*b))&255))*1099511628211
    return h
@export("pareto_optimization")
fn pareto_optimization(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>514:return -1
    let rows=Int(v[0]);let cols=Int(v[1]);if rows<1 or rows>64 or cols<1 or cols>8 or Int(n)!=2+rows*cols:return -1
    for i in range(rows*cols):if v[2+i] < -1000 or v[2+i]>1000:return -1
    var keep=InlineArray[Int64,64](fill=1);var kept:Int64=0
    for i in range(rows):
        for j in range(rows):
            if i==j:continue
            var ge=True;var gt=False
            for x in range(cols):let other=v[2+j*cols+x];let this=v[2+i*cols+x];if other<this:ge=False;if other>this:gt=True
            if ge and (gt or j<i):keep[i]=0;break
        if keep[i]!=0:kept+=1
    var h:UInt64=14695981039346656037;h=po_feed(h,kept);h=po_feed(h,Int64(cols))
    for i in range(rows):if keep[i]!=0:for x in range(cols):h=po_feed(h,v[2+i*cols+x])
    return Int64(h&0x7fffffffffffffff)
