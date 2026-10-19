from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("k_nn")
fn k_nn(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4:return -1
    let count=a[0];let dim=a[1];let k=a[2]
    if count<1 or count>32 or dim<1 or dim>8 or k<1 or k>count or k%2==0 or n!=c_size_t(3+count*dim+count+dim):return -1
    let laboff=3+Int(count*dim);let qoff=laboff+Int(count);var dists=InlineArray[Int64,32](fill=0);var labels=InlineArray[Int,32](fill=0)
    for i in range(Int(count)):
        var qnorm:Int64=0;var tnorm:Int64=0;var cross:Int64=0
        for j in range(Int(dim)):
            let q=a[qoff+j];let x=a[3+i*Int(dim)+j]
            if q< -32 or q>32 or x< -32 or x>32:return -1
            qnorm+=q*q;tnorm+=x*x;cross+=q*x
        dists[i]=qnorm-2*cross+tnorm
        labels[i]=Int(a[laboff+i]);if labels[i]<0 or labels[i]>1:return -1
        for prev in range(i):if dists[prev]==dists[i]:return -1
    var selected=InlineArray[Bool,32](fill=false);var votes=InlineArray[Int,2](fill=0)
    for rank in range(Int(k)):
        var best=-1
        for i in range(Int(count)):if not selected[i] and (best<0 or dists[i]<dists[best]):best=i
        selected[best]=true;votes[labels[best]]+=1
    return 0 if votes[0]>votes[1] else 1
