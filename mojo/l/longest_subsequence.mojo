from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn lseq_solve(a:InlineArray[Int64,10],n:Int,mut out:InlineArray[Int64,10])->Int:
    if n<=1:
        if n>0:out[0]=a[0]
        return n
    let pivot=a[0];var best=InlineArray[Int64,10](fill=0);var bestlen=0
    for i in range(1,n):
        if a[i]<pivot:
            var sub=InlineArray[Int64,10](fill=0);var m=0
            for j in range(i+1,n):
                if a[j]>=a[i]:sub[m]=a[j];m+=1
            var child=InlineArray[Int64,10](fill=0);let childlen=lseq_solve(sub,m,child)
            if childlen+1>bestlen:
                bestlen=childlen+1;best[0]=a[i]
                for j in range(childlen):best[j+1]=child[j]
    var sub=InlineArray[Int64,10](fill=0);var m=0
    for i in range(1,n):
        if a[i]>=pivot:sub[m]=a[i];m+=1
    var child=InlineArray[Int64,10](fill=0);let childlen=lseq_solve(sub,m,child)
    if childlen+1>bestlen:
        bestlen=childlen+1;best[0]=pivot
        for j in range(childlen):best[j+1]=child[j]
    for i in range(bestlen):out[i]=best[i]
    return bestlen
@export("longest_subsequence")
fn longest_subsequence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>11:return -1
    let count=v[0]
    if count<1 or count>10 or n!=c_size_t(count+1):return -1
    var a=InlineArray[Int64,10](fill=0);var out=InlineArray[Int64,10](fill=0)
    for i in range(Int(count)):
        a[i]=v[i+1]
        if a[i]<-10 or a[i]>10:return -1
    let len=lseq_solve(a,Int(count),out);var result:Int64=len
    for i in range(len):result=result*21+out[i]+10
    return result
