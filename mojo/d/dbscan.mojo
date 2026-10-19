from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List

@export("dbscan")
fn dbscan(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<5 or length>67:return -1
    let n=input[0];let eps=input[1];let min_pts=input[2]
    if n<1 or n>32 or eps<1 or eps>2000000 or min_pts<1 or min_pts>n or length!=c_size_t(3+2*n):return -1
    var xs=List[Int64](length=32,fill=0);var ys=List[Int64](length=32,fill=0);var labels=List[Int](length=32,fill=-1);var expanded=List[Int](length=32,fill=0)
    for i in range(Int(n)):
        xs[i]=input[3+2*i];ys[i]=input[4+2*i]
        if xs[i]<-1000000 or xs[i]>1000000 or ys[i]<-1000000 or ys[i]>1000000:return -1
        for j in range(i):
            if xs[i]==xs[j] and ys[i]==ys[j]:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(n):return -2
    let eps2=eps*eps;var next=0
    for i in range(Int(n)):
        if labels[i]>=0:continue
        var count=0
        for j in range(Int(n)):
            let dx=xs[i]-xs[j];let dy=ys[i]-ys[j]
            if dx*dx+dy*dy<=eps2:count+=1
        if count<min_pts:continue
        let cluster=next;next+=1;labels[i]=cluster
        var queue=List[Int](capacity=32);var queued=List[Int](length=32,fill=0)
        for j in range(Int(n)):
            let dx=xs[i]-xs[j];let dy=ys[i]-ys[j]
            if dx*dx+dy*dy<=eps2:queue.append(j);queued[j]=1
        var head=0
        while head<len(queue):
            let q=queue[head];head+=1
            if labels[q]>=0 and labels[q]!=cluster:continue
            labels[q]=cluster
            if expanded[q]!=0:continue
            expanded[q]=1
            var neighbors=0
            for j in range(Int(n)):
                let dx=xs[q]-xs[j];let dy=ys[q]-ys[j]
                if dx*dx+dy*dy<=eps2:neighbors+=1
            if neighbors>=min_pts:
                for j in range(Int(n)):
                    let dx=xs[q]-xs[j];let dy=ys[q]-ys[j]
                    if dx*dx+dy*dy<=eps2 and labels[j]<0 and queued[j]==0:queue.append(j);queued[j]=1
    for i in range(Int(n)):
        if labels[i]<0:output[i]=0
        else:output[i]=UInt8(labels[i]+1)
    return n
