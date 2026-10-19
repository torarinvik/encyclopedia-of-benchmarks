from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kth_element_finder")
fn kth_element_finder(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>259:return -9223372036854775808
    let mode=a[0];let count=a[1];let k=a[2]
    if (mode!=0 and mode!=1) or count<1 or count>256 or k<1 or k>count or n!=c_size_t(3+count):return -9223372036854775808
    var v=InlineArray[Int64,256]()
    for i in range(Int(count)):
        v[i]=a[3+i]
        if v[i]< -1000000 or v[i]>1000000:return -9223372036854775808
    # Heap selection: size k, min-heap for kth-largest and max-heap for kth-smallest.
    let want_min=(mode==0);let kk=Int(k)
    for i in range(kk//2-1,-1,-1):
        var p=i
        while 2*p+1<kk:
            var c=2*p+1
            if want_min:
                if c+1<kk and v[c+1]<v[c]:c+=1
                if v[p]<=v[c]:break
            else:
                if c+1<kk and v[c+1]>v[c]:c+=1
                if v[p]>=v[c]:break
            let t=v[p];v[p]=v[c];v[c]=t;p=c
    for i in range(kk,Int(count)):
        let improves=(v[i]>v[0] if want_min else v[i]<v[0])
        if improves:
            v[0]=v[i];var p=0
            while 2*p+1<kk:
                var c=2*p+1
                if want_min:
                    if c+1<kk and v[c+1]<v[c]:c+=1
                    if v[p]<=v[c]:break
                else:
                    if c+1<kk and v[c+1]>v[c]:c+=1
                    if v[p]>=v[c]:break
                let t=v[p];v[p]=v[c];v[c]=t;p=c
    return v[0]
