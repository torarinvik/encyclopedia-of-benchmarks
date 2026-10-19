from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("three_sum_problem")
fn three_sum_problem(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>259:return -1
    let target=a[0];let nv=a[1]
    if target< -2147483648 or target>2147483647 or nv<0 or nv>257 or n!=c_size_t(nv+2):return -1
    let count=Int(nv);var v=InlineArray[Int64,257]()
    for i in range(count):
        if a[i+2]< -100000 or a[i+2]>100000:return -1
        v[i]=a[i+2]
    for start in range(count/2):
        var root=count/2-1-start
        while root<count/2:
            var child=root*2+1
            if child+1<count and v[child]<v[child+1]:child+=1
            if v[root]>=v[child]:break
            let t=v[root];v[root]=v[child];v[child]=t;root=child
    for end0 in range(1,count):
        let end=count-end0;let t=v[0];v[0]=v[end];v[end]=t;var root=0
        while root<end/2:
            var child=root*2+1
            if child+1<end and v[child]<v[child+1]:child+=1
            if v[root]>=v[child]:break
            let z=v[root];v[root]=v[child];v[child]=z;root=child
    var triplets=0
    for first in range(max(count-2,0)):
        if first>0 and v[first]==v[first-1]:continue
        var l=first+1;var r=count-1
        while l<r:
            let sum=v[first]+v[l]+v[r]
            if sum<target:l+=1
            elif sum>target:r-=1
            else:
                triplets+=1;l+=1;r-=1
                while l<r and v[l]==v[l-1]:l+=1
                while l<r and v[r]==v[r+1]:r-=1
    if triplets*12>Int(cap) or (triplets>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var index=0
    for first in range(max(count-2,0)):
        if first>0 and v[first]==v[first-1]:continue
        var l=first+1;var r=count-1
        while l<r:
            let sum=v[first]+v[l]+v[r]
            if sum<target:l+=1
            elif sum>target:r-=1
            else:
                let x0=UInt32(Int32(v[first]));let x1=UInt32(Int32(v[l]));let x2=UInt32(Int32(v[r]))
                for b in range(4):
                    o[index*12+b]=UInt8((x0>>(8*b))&255)
                    o[index*12+4+b]=UInt8((x1>>(8*b))&255)
                    o[index*12+8+b]=UInt8((x2>>(8*b))&255)
                index+=1;l+=1;r-=1
                while l<r and v[l]==v[l-1]:l+=1
                while l<r and v[r]==v[r+1]:r-=1
    return Int64(triplets)
