from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longestpalindrome")
fn longestpalindrome(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65 or v[0]<0 or v[0]>64 or n!=c_size_t(v[0]+1):return -1
    var a=InlineArray[Int64,64](fill=0);var m=0
    for i in range(Int(v[0])):
        let x=v[i+1]
        if x<32 or x>126 or x==35:return -1
        if x!=32:a[m]=x;m+=1
    let z=2*m+1;var text=InlineArray[Int64,129](fill=0)
    for i in range(z):text[i]=if i%2==0:-1 else:a[i/2]
    var p=InlineArray[Int64,129](fill=0);var center=0;var right=0;var best=0
    for i in range(z):
        if i<right:
            let mirror=2*center-i;p[i]=min(p[mirror],right-i)
        while i>=p[i]+1 and i+p[i]+1<z and text[i-p[i]-1]==text[i+p[i]+1]:p[i]+=1
        best=max(best,p[i])
        if i+p[i]>right:center=i;right=i+Int(p[i])
    return best
