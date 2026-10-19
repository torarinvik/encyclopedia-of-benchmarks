from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sin,cos,asin,atan2,isfinite
@export("quaternions")
fn quaternions(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>10:return -1
    for i in range(Int(n)):if not isfinite(a[i]):return -1
    if a[0]!=0.0 and a[0]!=1.0 and a[0]!=2.0:return -1
    let op=Int(a[0]);let expected=4 if op==0 else (5 if op==1 else 9);let outlen=3 if op==1 else 4
    if n!=c_size_t(expected):return -1
    var v=InlineArray[Float32,8]()
    if op==0:
        for i in range(3):if a[i+1]< -3.0 or a[i+1]>3.0:return -1
        for i in range(3):v[i]=Float32(a[i+1])
    elif op==1:
        for i in range(4):v[i]=Float32(a[i+1]);if v[i]< -1.0 or v[i]>1.0:return -1
        var norm=v[0]*v[0];norm=norm+v[1]*v[1];norm=norm+v[2]*v[2];norm=norm+v[3]*v[3]
        if abs(norm-Float32(1.0))>Float32(1.0e-6):return -1
        var arg=v[0]*v[2]+v[1]*v[3];arg=Float32(2.0)*arg
        if arg< -1.0 or arg>1.0:return -1
    else:
        for i in range(8):if a[i+1]< -1.0 or a[i+1]>1.0:return -1;v[i]=Float32(a[i+1])
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(outlen):return -2
    var z=InlineArray[Float32,4]()
    if op==0:
        let yaw=v[0];let pitch=v[1];let roll=v[2];let cy=Float32(cos(Float64(yaw*0.5)));let sy=Float32(sin(Float64(yaw*0.5)));let cp=Float32(cos(Float64(pitch*0.5)));let sp=Float32(sin(Float64(pitch*0.5)));let cr=Float32(cos(Float64(roll*0.5)));let sr=Float32(sin(Float64(roll*0.5)))
        z[0]=(cr*cp)*cy+(sr*sp)*sy;z[1]=(sr*cp)*cy-(cr*sp)*sy;z[2]=(cr*sp)*cy+(sr*cp)*sy;z[3]=(cr*cp)*sy-(sr*sp)*cy
    elif op==1:
        let w=v[0];let x=v[1];let y=v[2];let zc=v[3];let ry=Float32(2.0)*(w*x+y*zc);let rx=Float32(1.0)-Float32(2.0)*(x*x+y*y);let pa=Float32(2.0)*(w*y+x*zc);let yy=Float32(2.0)*(w*zc+x*y);let yx=Float32(1.0)-Float32(2.0)*(y*y+zc*zc)
        z[0]=Float32(atan2(Float64(ry),Float64(rx)));z[1]=Float32(asin(Float64(pa)));z[2]=Float32(atan2(Float64(yy),Float64(yx)))
    else:
        let aw=v[0];let a1=v[1];let a2=v[2];let a3=v[3];let bw=v[4];let b1=v[5];let b2=v[6];let b3=v[7]
        z[0]=((aw*bw-a1*b1)-a2*b2)-a3*b3;z[1]=((aw*b1+a1*bw)+a2*b3)-a3*b2;z[2]=((aw*b2-a1*b3)+a2*bw)+a3*b1;z[3]=((aw*b3+a1*b2)-a2*b1)+a3*bw
    for i in range(outlen):o[i]=Float64(z[i])
    return outlen
