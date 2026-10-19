from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("jaro_winkler")
fn jaro_winkler(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1.0e300
    let n1=Int(v[0]);if n1<0 or n1>32 or 1+n1>=Int(n):return -1.0e300
    let p=1+n1;let n2=Int(v[p]);if n2<0 or n2>32 or n!=c_size_t(p+1+n2):return -1.0e300
    var a=InlineArray[Int,32](fill=0);var b=InlineArray[Int,32](fill=0)
    for i in range(n1):if v[i+1]<0 or v[i+1]>127:return -1.0e300;a[i]=Int(v[i+1])
    for i in range(n2):if v[p+1+i]<0 or v[p+1+i]>127:return -1.0e300;b[i]=Int(v[p+1+i])
    let rad=(n1 if n1<n2 else n2)//2;var ua=InlineArray[Bool,32](fill=False);var ub=InlineArray[Bool,32](fill=False);var ma=InlineArray[Int,32](fill=0);var mb=InlineArray[Int,32](fill=0);var ca=0;var cb=0
    for i in range(n1):
        let lo=0 if i-rad<0 else i-rad;let hi=n2 if i+rad+1>n2 else i+rad+1
        for j in range(lo,hi):if not ub[j] and a[i]==b[j]:ub[j]=True;ma[ca]=a[i];ca+=1;break
    for i in range(n2):
        let lo=0 if i-rad<0 else i-rad;let hi=n1 if i+rad+1>n1 else i+rad+1
        for j in range(lo,hi):if not ua[j] and b[i]==a[j]:ua[j]=True;mb[cb]=b[i];cb+=1;break
    var trans=0
    for i in range(ca):if i<cb and ma[i]!=mb[i]:trans+=1
    trans//=2;var jaro=0.0
    if ca>0:jaro=(Float64(ca)/Float64(n1)+Float64(ca)/Float64(n2)+Float64(ca-trans)/Float64(ca))/3.0
    var pre=0
    while pre<4 and pre<n1 and pre<n2 and a[pre]==b[pre]:pre+=1
    return jaro+0.1*Float64(pre)*(1.0-jaro)
