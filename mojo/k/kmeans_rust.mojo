from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kmeans_rust")
fn kmeans_rust(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>10 or a[0]<2 or a[0]>8 or n!=c_size_t(a[0]+1):return -1
    let count=Int(a[0]);var pts=InlineArray[Float64,8]();var centers=InlineArray[Float64,2]();var labels=InlineArray[Int64,8]()
    for i in range(count):
        if a[i+1]<-16 or a[i+1]>16 or (i>0 and a[i]>=a[i+1]):return -1
        pts[i]=Float64(a[i+1])
    centers[0]=pts[0];centers[1]=pts[count//2]
    for i in range(count):let d0=pts[i]-centers[0];let d1=pts[i]-centers[1];labels[i]=1 if d1*d1<d0*d0 else 0
    for _ in range(256):
        var sums=InlineArray[Float64,2]();var cnt=InlineArray[Int64,2]()
        for i in range(count):sums[Int(labels[i])]+=pts[i];cnt[Int(labels[i])]+=1
        if cnt[0]==0 or cnt[1]==0:return -1
        centers[0]=sums[0]/Float64(cnt[0]);centers[1]=sums[1]/Float64(cnt[1]);var changed=False
        for i in range(count):let d0=pts[i]-centers[0];let d1=pts[i]-centers[1];let q:Int64=1 if d1*d1<d0*d0 else 0;if q!=labels[i]:changed=True;labels[i]=q
        if not changed:
            var packed:Int64=0
            for i in range(count):packed|=labels[i]<<i
            return packed
    return -2
