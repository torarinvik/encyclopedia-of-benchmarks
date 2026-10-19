from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("sherman_morrison")
fn sherman_morrison(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>25:return -1
    let nf=a[0];if nf!=Float64(Int64(nf)) or nf<1 or nf>4:return -1
    let d=Int(nf);if n!=c_size_t(1+d*d+2*d):return -1
    var m=InlineArray[Float64,16]();var u=InlineArray[Float64,4]();var v=InlineArray[Float64,4]();var p=1
    for i in range(d*d+d+d):let x=a[p+i];if x!=Float64(Int64(x)) or x< -2 or x>2:return -1
    for i in range(d*d):m[i]=a[p+i]
    p+=d*d;for i in range(d):u[i]=a[p+i];p+=d*d*0
    for i in range(d):v[i]=a[1+d*d+d+i]
    var right=InlineArray[Float64,4]();for c in range(d):for j in range(d):right[c]+=v[j]*m[j*d+c]
    var den=0.0;for j in range(d):den+=right[j]*u[j];den+=1.0
    if o==UnsafePointer[Float64,MutAnyOrigin]():return -2
    if den==0:return 0
    if cap<c_size_t(d*d):return -2
    var left=InlineArray[Float64,4]();for r in range(d):for j in range(d):left[r]+=m[r*d+j]*u[j]
    let recip=1.0/den;var out=InlineArray[Float64,16]()
    for r in range(d):for c in range(d):let outer=left[r]*right[c];let scaled=outer*recip;out[r*d+c]=m[r*d+c]-scaled
    for i in range(d*d):o[i]=out[i]
    return Int64(d*d)
