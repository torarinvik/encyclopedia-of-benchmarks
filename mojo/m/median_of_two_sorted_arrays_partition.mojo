from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("median_of_two_sorted_arrays_partition")
fn median_of_two_sorted_arrays_partition(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 3 or n > 2002: return -2000001
    let a=v[0]; let b=v[1]
    if a<0 or b<0 or a>1000 or b>1000 or a+b<1 or a+b>2000 or Int(n)!=Int(a+b)+2:return -2000001
    let bs=Int(a)+2
    for i in range(Int(a)):
        if v[i+2] < -1000000 or v[i+2] > 1000000 or (i>0 and v[i+1]>v[i+2]):return -2000001
    for i in range(Int(b)):
        if v[bs+i] < -1000000 or v[bs+i] > 1000000 or (i>0 and v[bs+i-1]>v[bs+i]):return -2000001
    let short_count=Int(min(a,b));let long_count=Int(max(a,b))
    var short=InlineArray[Int64,1000](fill=0);var long=InlineArray[Int64,1000](fill=0)
    if a<=b:
        for i in range(Int(a)):short[i]=v[2+i]
        for i in range(Int(b)):long[i]=v[bs+i]
    else:
        for i in range(Int(b)):short[i]=v[bs+i]
        for i in range(Int(a)):long[i]=v[2+i]
    var lo=0;var hi=short_count;let left=(Int(a+b)+1)//2
    while lo<=hi:
        let cut=lo+(hi-lo)//2;let other=left-cut
        let al=if cut==0:-9223372036854775807 else:short[cut-1]
        let ar=if cut==short_count:9223372036854775807 else:short[cut]
        let bl=if other==0:-9223372036854775807 else:long[other-1]
        let br=if other==long_count:9223372036854775807 else:long[other]
        if al<=br and bl<=ar:
            let lm=if al>bl:al else:bl
            if (a+b)%2==1:return lm*2
            let rm=if ar<br:ar else:br
            return lm+rm
        elif al>br:hi=cut-1
        else:lo=cut+1
    return -2000001
