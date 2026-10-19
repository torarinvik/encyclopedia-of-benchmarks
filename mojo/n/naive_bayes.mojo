from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import log
@export("naive_bayes")
fn naive_bayes(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>37 or a[0]<2 or a[0]>8 or a[1]<1 or a[1]>3:return -1
    let rows=Int(a[0]);let f=Int(a[1]);if n!=c_size_t(2+rows*(f+1)+f):return -1
    var labels=InlineArray[Int64,8]();var vals=InlineArray[Float64,24]();var class_order=InlineArray[Int64,3]();var counts=InlineArray[Int64,3]();var nc=0;var pos=2
    for r in range(rows):
        let label=a[pos];pos+=1;if label<0 or label>2:return -1
        var c=0
        while c<nc and class_order[c]!=label:c+=1
        if c==nc:class_order[nc]=label;nc+=1
        labels[r]=c;counts[c]+=1
        for j in range(f):let z=a[pos];pos+=1;if z< -10000 or z>10000:return -1;vals[r*f+j]=Float64(z)/1000.0
    if nc<2:return -1
    for j in range(f):if a[pos+j]< -10000 or a[pos+j]>10000:return -1
    var best=-1.0e300;var answer=class_order[0]
    for c in range(nc):
        var score=log(Float64(counts[c])/Float64(rows))
        for j in range(f):
            var mean:Float64=0.0
            for r in range(rows):if labels[r]==c:mean+=vals[r*f+j]
            mean/=Float64(counts[c]);var variance:Float64=0.0
            for r in range(rows):if labels[r]==c:let d=vals[r*f+j]-mean;variance+=d*d
            variance=max(variance/Float64(counts[c]),1e-9);let q=Float64(a[pos+j])/1000.0;let d=q-mean
            score+=-0.5*log(6.283185307179586*variance)-d*d/(2.0*variance)
        if score>best:best=score;answer=class_order[c]
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    let bits=UInt64(answer);for b in range(8):o[b]=UInt8((bits>>(8*b))&255)
    return 8
