from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, abs, isfinite
@export("qr_eigen_values")
fn qr_eigen_values(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<5 or n>6:return -1
    let dim=a[0]
    if dim!=2.0 or n!=5:return -1
    var m=InlineArray[Float64,4]()
    for i in range(4):
        let x=a[i+1]
        if not isfinite(x) or Float64(Int64(x))!=x or x< -9.0 or x>9.0:return -1
        m[i]=x
    if m[1]!=m[2] or m[1]==0.0 or m[0]==m[3]:return -1
    var v0=m[0];var v1=m[1];var v2=m[2];var v3=m[3]
    var eig0:Float64=0.0;var eig1:Float64=0.0
    var it=0;var last_shift:Float64=0.0
    while abs(v2)>1.0e-10 and it<256:
        let shift=v3;last_shift=shift;let b00=v0-shift;let b01=v1;let b10=v2;let b11=0.0
        let c0=sqrt(b00*b00+b10*b10)
        if c0==0.0:return -1
        let q00=b00/c0;let q10=b10/c0
        let r00=c0;let r01=q00*b01+q10*b11
        let rem1=b01-q00*r01;let rem2=b11-q10*r01;let c1=sqrt(rem1*rem1+rem2*rem2)
        if c1==0.0:return -1
        let q01=rem1/c1;let q11=rem2/c1
        let r11=c1
        let n00=r00*q00+r01*q10+shift
        let n01=r00*q01+r01*q11
        let n10=r11*q10
        let n11=r11*q11+shift
        v0=n00;v1=n01;v2=n10;v3=n11;it+=1
    if abs(v2)>1.0e-10:return -1
    # Source deflation emits the remaining top-left diagonal then the last active shift.
    eig0=v0;eig1=last_shift
    if not isfinite(eig0) or not isfinite(eig1):return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<2:return -2
    o[0]=eig0;o[1]=eig1;return 2
