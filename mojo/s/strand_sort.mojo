from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("strand_sort")
fn strand_sort(a:UnsafePointer[Int64,MutAnyOrigin],scratch:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if n<2:return
    let length=Int(n);var remaining=length;var resultlen=0
    while remaining>0:
        var strand=0;var write=0
        for read in range(remaining):
            let x=a[read]
            if strand==0 or x>=scratch[strand-1]:scratch[strand]=x;strand+=1
            else:a[write]=x;write+=1
        let oldstart=length-resultlen;let newstart=oldstart-strand
        for i in range(resultlen):a[newstart+i]=a[oldstart+i]
        var left=resultlen;var right=strand;var dst=length
        while left>0 and right>0:
            if a[newstart+left-1]>scratch[right-1]:
                left-=1;dst-=1;a[dst]=a[newstart+left]
            else:
                right-=1;dst-=1;a[dst]=scratch[right]
        while right>0:right-=1;dst-=1;a[dst]=scratch[right]
        remaining=write;resultlen+=strand
