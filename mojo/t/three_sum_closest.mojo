from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("three_sum_closest")
fn three_sum_closest(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>514:return -9000000000000000000
    let target=a[0];let nv=a[1]
    if target< -2147483648 or target>2147483647 or nv<3 or nv>512 or n!=c_size_t(nv+2):return -9000000000000000000
    var v=InlineArray[Int64,512]()
    for i in range(Int(nv)):
        if a[i+2]< -2147483648 or a[i+2]>2147483647:return -9000000000000000000
        v[i]=a[i+2]
    let count=Int(nv)
    for start in range(count/2):
        var root=count/2-1-start
        while root<count/2:
            var child=root*2+1
            if child+1<count and v[child]<v[child+1]:child+=1
            if v[root]>=v[child]:break
            let t=v[root];v[root]=v[child];v[child]=t;root=child
    for end0 in range(1,count):
        let end=count-end0;let t=v[0];v[0]=v[end];v[end]=t
        var root=0
        while root<(end/2):
            var child=root*2+1
            if child+1<end and v[child]<v[child+1]:child+=1
            if v[root]>=v[child]:break
            let z=v[root];v[root]=v[child];v[child]=z;root=child
    var best=v[0]+v[1]+v[2];var bestdiff=target-best
    if bestdiff<0:bestdiff = -bestdiff
    for first in range(count-2):
        var left=first+1;var right=count-1
        while left<right:
            let sum=v[first]+v[left]+v[right];var diff=target-sum
            if diff<0:diff = -diff
            if diff<bestdiff or (diff==bestdiff and sum<best):best=sum;bestdiff=diff
            if sum<target:left+=1
            elif sum>target:right-=1
            else:return sum
    return best
