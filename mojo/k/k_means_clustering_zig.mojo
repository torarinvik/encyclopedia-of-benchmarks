from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("k_means_clustering_zig")
fn k_means_clustering_zig(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1
    let count=a[0];if count<2 or count>8 or n!=c_size_t(count+1):return -1
    var points=InlineArray[Float32,8](fill=0.0);var centers=InlineArray[Float32,2](fill=0.0)
    for i in range(Int(count)):
        if a[i+1]< -16 or a[i+1]>16 or (i>0 and a[i+1]<=a[i]):return -1
        points[i]=Float32(a[i+1])
    centers[0]=points[0];centers[1]=points[1];var oldcounts=InlineArray[Int,2](fill=0)
    for iteration in range(64):
        var counts=InlineArray[Int,2](fill=0);var sums=InlineArray[Float32,2](fill=0.0)
        for i in range(Int(count)):
            let d0=(points[i]-centers[0])*(points[i]-centers[0]);let d1=(centers[1]-points[i])*(centers[1]-points[i]);let c=1 if d1<d0 else 0
            counts[c]+=1;sums[c]+=points[i]
        if counts[0]==0 or counts[1]==0:return -1
        let next0=sums[0]/Float32(counts[0]);let next1=sums[1]/Float32(counts[1])
        if next0==centers[0] and next1==centers[1] and counts[0]==oldcounts[0] and counts[1]==oldcounts[1]:
            let code0=Int64(next0*256.0)+4097;let code1=Int64(next1*256.0)+4097
            return ((code0*8194+code1)*81)+counts[0]*9+counts[1]
        centers[0]=next0;centers[1]=next1;oldcounts=counts
    return -2
