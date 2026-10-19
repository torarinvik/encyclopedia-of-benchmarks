from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("jaro_similarity")
fn jaro_similarity(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1.0e300
    let n1=Int(v[0]);if n1<0 or n1>32 or 1+n1>=Int(n):return -1.0e300
    let p=1+n1;let n2=Int(v[p]);if n2<0 or n2>32 or n1<n2 or n!=c_size_t(p+1+n2):return -1.0e300
    var a=InlineArray[Int64,32](fill=0);var b=InlineArray[Int64,32](fill=0)
    for i in range(n1):if v[i+1]<0 or v[i+1]>127:return -1.0e300;a[i]=v[i+1]
    for i in range(n2):if v[p+1+i]<0 or v[p+1+i]>127:return -1.0e300;b[i]=v[p+1+i]
    if n1==n2:
        var eq=True
        for i in range(n1):if a[i]!=b[i]:eq=False
        if eq:return 1.0
    var rad=n1//2-1;if rad<0:rad=0
    var ma=InlineArray[Bool,32](fill=False);var mb=InlineArray[Bool,32](fill=False);var m=0
    for i in range(n1):
        let lo=0 if i-rad<0 else i-rad;let hi=n2-1 if i+rad>=n2 else i+rad
        for j in range(lo,hi+1):if a[i]==b[j] and not mb[j]:m+=1;ma[i]=True;mb[j]=True;break
    if m==0:return 0.0
    var trans=0;var j=0
    for i in range(n1):
        if ma[i]:
            while not mb[j]:j+=1
            if a[i]!=b[j]:trans+=1
            j+=1
    trans//=2
    return (Float64(m)/Float64(n1)+Float64(m)/Float64(n2)+Float64(m-trans)/Float64(m))/3.0
