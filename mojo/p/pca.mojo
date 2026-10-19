from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("pca")
fn pca(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<9 or n>19:return -1
    let count=Int(v[0]);if v[1]!=2.0 or v[2]!=1.0 or count<3 or count>8 or v[0]!=Float64(count) or Int(n)!=3+2*count:return -1
    var x=InlineArray[Float64,8](fill=0.0);var y=InlineArray[Float64,8](fill=0.0);var mx=0.0;var my=0.0
    for i in range(count):x[i]=v[3+2*i];y[i]=v[4+2*i];if not is_finite(x[i]) or not is_finite(y[i]) or abs(x[i])>1000.0 or abs(y[i])>1000.0:return -1;mx+=x[i];my+=y[i]
    mx/=Float64(count);my/=Float64(count);var sx=0.0;var sy=0.0
    for i in range(count):let dx=x[i]-mx;let dy=y[i]-my;sx+=dx*dx;sy+=dy*dy
    let denom=Float64(count-1);if sx<=0.0 or sy<=0.0:return -1
    let scale0=sqrt(sx/denom);let scale1=sqrt(sy/denom);var z0=InlineArray[Float64,8](fill=0.0);var z1=InlineArray[Float64,8](fill=0.0);var a=0.0;var b=0.0;var d=0.0
    for i in range(count):z0[i]=(x[i]-mx)/scale0;z1[i]=(y[i]-my)/scale1;a+=z0[i]*z0[i];b+=z0[i]*z1[i];d+=z1[i]*z1[i]
    a/=denom;b/=denom;d/=denom;let root=sqrt((a-d)*(a-d)+4.0*b*b);let l0=0.5*(a+d+root);let l1=0.5*(a+d-root);if l0-l1<=1e-8:return -1
    var vx=0.0;var vy=0.0
    if b==0.0:vx=1.0 if a>=d else 0.0;vy=0.0 if a>=d else 1.0
    else:vx=b;vy=l0-a;let norm=sqrt(vx*vx+vy*vy);if norm==0.0:return -1;vx/=norm;vy/=norm
    if (abs(vx)>=abs(vy) and vx<0.0) or (abs(vy)>abs(vx) and vy<0.0):vx=-vx;vy=-vy
    let size=count+4;if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(size):return -2
    for i in range(count):o[i]=z0[i]*vx+z1[i]*vy
    o[count]=vx;o[count+1]=vy;o[count+2]=l0;o[count+3]=l1;return Int64(size)
