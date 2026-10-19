from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("simplex")
fn simplex(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>132:return -1.0e300
    let nv=a[0];let na=a[1];let nr=a[2];let nc=a[3]
    if nv<2 or nv>4 or na<0 or na>2 or nr<3 or nr>8 or nc<nv+na+1 or nc>16 or n!=c_size_t(4+nr*nc):return -1.0e300
    var t=InlineArray[Float64,128]()
    for r in range(Int(nr)):for c in range(Int(nc)):t[r*16+c]=Float64(a[4+r*Int(nc)+c])/1e6
    for r in range(Int(nr)):if t[r*16+Int(nc)-1]<0:return -1.0e300
    var phase=na!=0;var finished=False
    for _ in range(100):
        if finished:return abs(t[Int(nc)-1])
        let stages=2 if phase else 1;let sign=1.0 if phase else -1.0
        var pc=0;var best=sign*t[0]
        for c in range(1,Int(nc)-1):let score=sign*t[c];if score>best:best=score;pc=c
        if best<=0:
            if phase:
                let first=Int(nc)-Int(na)-1;var compact=InlineArray[Float64,128]()
                for r in range(1,Int(nr)):
                    var k=0
                    for c in range(Int(nc)):
                        if c>=first and c<Int(nc)-1:continue
                        compact[(r-1)*16+k]=t[r*16+c];k+=1
                nr-=1;nc-=na;na=0;t=compact;phase=False
            else:finished=True
            continue
        var found=False;var pr=0;var ratio=0.0
        for r in range(stages,Int(nr)):
            let divisor=t[r*16+pc]
            if divisor>0:
                let q=t[r*16+Int(nc)-1]/divisor
                if not found or q<ratio:found=True;ratio=q;pr=r
        if not found:return -1.0e300
        let pivot=t[pr*16+pc];var norm=InlineArray[Float64,16]();var col=InlineArray[Float64,8]()
        for c in range(Int(nc)):norm[c]=t[pr*16+c]/pivot
        for r in range(Int(nr)):col[r]=t[r*16+pc]
        for r in range(Int(nr)):for c in range(Int(nc)):t[r*16+c]+=( -col[r])*norm[c]
        for c in range(Int(nc)):t[pr*16+c]=norm[c]
        for r in range(Int(nr)):for c in range(Int(nc)):if t[r*16+c]!=t[r*16+c] or abs(t[r*16+c])>1e300:return -1.0e300
    return -1.0e300
