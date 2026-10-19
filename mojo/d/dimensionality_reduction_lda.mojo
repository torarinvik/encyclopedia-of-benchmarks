from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
from std.math import sqrt
@export("dimensionality_reduction_lda")
fn dimensionality_reduction_lda(input:UnsafePointer[Float64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or length<16 or input[0]!=2.0 or input[2]!=2.0 or input[3]!=1.0 or input[1]<4.0 or input[1]>8.0 or Float64(Int64(input[1]))!=input[1]:return -1
    let n=Int(input[1])
    if length!=c_size_t(4+3*n):return -1
    var x=List[Float64](capacity=8);var y=List[Float64](capacity=8);var labels=List[Int](capacity=8);var c0=0;var c1=0;var m00:Float64=0.0;var m01:Float64=0.0;var m10:Float64=0.0;var m11:Float64=0.0
    for i in range(n):
        let xv=input[4+i];let yv=input[4+n+i];let lv=input[4+2*n+i]
        if xv!=xv or yv!=yv or xv>10000.0 or xv< -10000.0 or yv>10000.0 or yv< -10000.0 or (lv!=0.0 and lv!=1.0):return -1
        x.append(xv);y.append(yv);labels.append(Int(lv))
        if lv==0.0:c0+=1;m00+=xv;m01+=yv
        else:c1+=1;m10+=xv;m11+=yv
    if c0<2 or c1<2:return -1
    m00/=Float64(c0);m01/=Float64(c0);m10/=Float64(c1);m11/=Float64(c1)
    var a:Float64=0.0;var b:Float64=0.0;var d:Float64=0.0
    for i in range(n):
        let mx=m00 if labels[i]==0 else m10;let my=m01 if labels[i]==0 else m11;let dx=x[i]-mx;let dy=y[i]-my
        a+=dx*dx;b+=dx*dy;d+=dy*dy
    a/=Float64(n);b/=Float64(n);d/=Float64(n);let det=a*d-b*b
    if det<=1.0e-12:return -1
    let dx=m10-m00;let dy=m11-m01;var w0=(d*dx-b*dy)/det;var w1=(a*dy-b*dx)/det;let norm=sqrt(w0*w0+w1*w1)
    if norm<=1.0e-12:return -1
    w0/=norm;w1/=norm
    if w0<0.0 or ((w0<1.0e-14 and w0> -1.0e-14) and w1<0.0):w0= -w0;w1= -w1
    var staged=List[Float64](capacity=8)
    for i in range(n):staged.append(w0*x[i]+w1*y[i])
    if out==UnsafePointer[Float64,MutAnyOrigin]() or capacity<c_size_t(n):return -2
    for i in range(n):out[i]=staged[i]
    return Int64(n)
