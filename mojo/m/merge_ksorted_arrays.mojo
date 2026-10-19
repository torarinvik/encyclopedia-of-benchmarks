from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("merge_ksorted_arrays")
fn merge_ksorted_arrays(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>146 or v[0]<1 or v[0]>16:return -1
    let k=Int(v[0]);var starts=InlineArray[Int64,16](fill=0);var lens=InlineArray[Int64,16](fill=0);var pos=1;var total=0
    for a in range(k):
        if pos>=Int(n):return -1
        let count=v[pos];pos+=1
        if count<0 or count>128-total or count>Int(n)-pos:return -1
        starts[a]=Int64(pos);lens[a]=count
        for i in range(Int(count)):
            let z=v[pos+i]
            if z < -1000000 or z > 1000000 or (i>0 and v[pos+i-1]>z):return -1
        pos+=Int(count);total+=Int(count)
    if pos!=Int(n):return -1
    var curs=InlineArray[Int64,16](fill=0);var sum:Int64=0
    for outi in range(total):
        var best=-1;var bv:Int64=0
        for a in range(k):
            if curs[a]<lens[a]:
                let val=v[Int(starts[a]+curs[a])]
                if best<0 or val<bv:best=a;bv=val
        if best<0:return -1
        sum+=Int64(outi+1)*(bv+1000001);curs[best]+=1
    return sum
