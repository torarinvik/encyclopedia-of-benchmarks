from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("jaro_winkler_distance")
fn jaro_winkler_distance(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1
    let n1=Int(v[0]);if n1<0 or n1>32 or 1+n1>=Int(n):return -1
    let p=1+n1;let n2=Int(v[p]);if n2<0 or n2>32 or n1<n2 or n!=c_size_t(p+1+n2):return -1
    var a=InlineArray[Int64,32](fill=0);var b=InlineArray[Int64,32](fill=0)
    for i in range(n1):if v[i+1]<0 or v[i+1]>127:return -1;a[i]=v[i+1]
    for i in range(n2):if v[p+1+i]<0 or v[p+1+i]>127:return -1;b[i]=v[p+1+i]
    var eq=n1==n2
    for i in range(n1):if a[i]!=b[i]:eq=False
    if eq:return 0
    if n2==0:return 1000000000
    var rad=n1//2-1;if rad<0:rad=0
    var ma=InlineArray[Bool,32](fill=False);var mb=InlineArray[Bool,32](fill=False);var m=0
    for i in range(n1):
        let lo=0 if i<rad else i-rad;let hi=n2-1 if i+rad>=n2 else i+rad
        if lo<=hi:
            for j in range(lo,hi+1):if a[i]==b[j] and not mb[j]:ma[i]=True;mb[j]=True;m+=1;break
    if m==0:return 1000000000
    var j=0;var trans=0
    for i in range(n1):
        if ma[i]:
            while j<n2 and not mb[j]:j+=1
            if j==n2:return -1
            if a[i]!=b[j]:trans+=1
            j+=1
    let mm=Int64(m);let t=Int64(trans//2);let l1=Int64(n1);let l2=Int64(n2)
    let jn=mm*mm*l2+mm*mm*l1+(mm-t)*l1*l2;let jd=3*l1*l2*mm
    var pre=0;let lim=4 if n2>4 else n2
    while pre<lim and a[pre]==b[pre]:pre+=1
    let den=10*jd;let num=Int64(10-pre)*(jd-jn)
    return (num*1000000000+den//2)//den
