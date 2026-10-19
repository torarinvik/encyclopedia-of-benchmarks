from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("k_means_clust")
fn k_means_clust(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<6:return -1
    let np=a[0];let dim=a[1];let k=a[2]
    if np<1 or np>16 or dim<1 or dim>4 or k<1 or k>4 or k>np or Float64(Int(np))!=np or Float64(Int(dim))!=dim or Float64(Int(k))!=k or n!=c_size_t(3+Int(np+dim*np+k*dim)):return -1
    let count=Int(np);let d=Int(dim);let clusters=Int(k);let dataoff=3;let centoff=dataoff+count*d
    var points=InlineArray[Float64,64](fill=0.0);var centers=InlineArray[Float64,16](fill=0.0)
    for i in range(count*d):
        let x=a[dataoff+i];if x< -16.0 or x>16.0 or Float64(Int64(x))!=x:return -1
        points[i]=x
    for i in range(clusters*d):
        let x=a[centoff+i];if x< -16.0 or x>16.0 or Float64(Int64(x))!=x:return -1
        centers[i]=x
    var labels=InlineArray[Int,16](fill=0);var sums=InlineArray[Float64,16](fill=0.0);var counts=InlineArray[Int,4](fill=0)
    for i in range(count):
        var best=0;var bestdist=1.0e300
        for c in range(clusters):
            var ds=0.0
            for j in range(d):let delta=points[i*d+j]-centers[c*d+j];ds+=delta*delta
            let dist=sqrt(ds)
            if dist<bestdist:bestdist=dist;best=c
        labels[i]=best;counts[best]+=1
        for j in range(d):sums[best*d+j]+=points[i*d+j]
    for c in range(clusters):if counts[c]==0:return -1
    let required=count+clusters*d
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(required):return -2
    for i in range(count):o[i]=Float64(labels[i])
    for c in range(clusters):for j in range(d):o[count+c*d+j]=sums[c*d+j]/Float64(counts[c])
    return Int64(required)
