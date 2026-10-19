from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sc_check(x:Float64,y:Float64,r:Float64,px:UnsafePointer[Int64,ImmutAnyOrigin],n:Int)->Bool:
    for i in range(n):let dx=Float64(px[2*i])-x;let dy=Float64(px[2*i+1])-y;if dx*dx+dy*dy>r*r+1e-12:return False
    return True
@export("smallest_circle")
fn smallest_circle(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>24 or n%2!=0:return -1
    let count=Int(n)/2
    for i in range(Int(n)):if a[i]< -100 or a[i]>100:return -1
    var cx=Float64(a[0]);var cy=Float64(a[1]);var radius=0.0;var found=count==1
    if count>1:
        for i in range(count):for j in range(i+1,count):for k in range(j+1,count):
            let x1=Float64(a[2*i]);let y1=Float64(a[2*i+1]);let x2=Float64(a[2*j]);let y2=Float64(a[2*j+1]);let x3=Float64(a[2*k]);let y3=Float64(a[2*k+1])
            let d=2.0*(x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2))
            if d==0.0:continue
            let q1=x1*x1+y1*y1;let q2=x2*x2+y2*y2;let q3=x3*x3+y3*y3
            let x=(q1*(y2-y3)+q2*(y3-y1)+q3*(y1-y2))/d
            let y=(q1*(x3-x2)+q2*(x1-x3)+q3*(x2-x1))/d
            let dx=x-x1;let dy=y-y1;let r=(dx*dx+dy*dy)**0.5
            if sc_check(x,y,r,a,count) and (not found or r<=radius):cx=x;cy=y;radius=r;found=true
        for i in range(count):for j in range(i+1,count):
            let x1=Float64(a[2*i]);let y1=Float64(a[2*i+1]);let x2=Float64(a[2*j]);let y2=Float64(a[2*j+1]);let x=(x1+x2)/2.0;let y=(y1+y2)/2.0
            let dx=x-x1;let dy=y-y1;let r=(dx*dx+dy*dy)**0.5
            if sc_check(x,y,r,a,count) and (not found or r<=radius):cx=x;cy=y;radius=r;found=true
    if not found:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<24:return -2
    var vals=InlineArray[Float64,3]();vals[0]=cx;vals[1]=cy;vals[2]=radius
    for i in range(3):let bits=bitcast[UInt64](vals[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return 1
