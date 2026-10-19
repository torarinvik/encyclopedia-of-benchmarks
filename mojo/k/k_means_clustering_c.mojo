from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("k_means_clustering_c")
fn k_means_clustering_c(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<7:return -1
    let count=a[0];if count<3 or count>8 or n!=c_size_t(1+2*count):return -1
    var labels=InlineArray[Int,8](fill=0);var x=InlineArray[Int,8](fill=0);var counts=InlineArray[Int,2](fill=0);var sum=InlineArray[Int64,2](fill=0)
    for i in range(Int(count)):
        labels[i]=Int(a[1+i]);x[i]=Int(a[1+Int(count)+i])
        if labels[i]<0 or labels[i]>1 or x[i]< -16 or x[i]>16:return -1
        if i>0 and x[i]<=x[i-1]:return -1
        counts[labels[i]]+=1;sum[labels[i]]+=Int64(x[i])
    if counts[0]==0 or counts[1]==0:return -1
    var pass=0;var changed=true
    while changed and pass<64:
        let c0=Float64(sum[0])/Float64(counts[0]);let c1=Float64(sum[1])/Float64(counts[1]);var nc=InlineArray[Int,2](fill=0);var ns=InlineArray[Int64,2](fill=0);changed=false
        for i in range(Int(count)):
            let newlabel=1 if abs(Float64(x[i])-c1)<abs(Float64(x[i])-c0) else 0
            if newlabel!=labels[i]:changed=true
            labels[i]=newlabel;nc[newlabel]+=1;ns[newlabel]+=Int64(x[i])
        if nc[0]==0 or nc[1]==0:return -1
        counts=nc;sum=ns;pass+=1
    if changed:return -2
    let q0=Int64(Float64(sum[0])*256.0/Float64(counts[0]));let q1=Int64(Float64(sum[1])*256.0/Float64(counts[1]))
    return (q0+4097)*8194+(q1+4097)
