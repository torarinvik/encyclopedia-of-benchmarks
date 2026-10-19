from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("otsu_threshold")
fn otsu_threshold(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>33 or v[0]<1 or v[0]>32 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0]);var hist=InlineArray[Int64,256](fill=0)
    for i in range(count):
        let px=v[i+1]
        if px<0 or px>255:return -1
        hist[Int(px)]+=1
    var total:Float64=0.0
    for i in range(256):total+=Float64(i)*Float64(hist[i])
    var maxv:Float64=0.0;var sum:Float64=0.0;var wb=0;var threshold=0
    for i in range(256):
        wb+=Int(hist[i])
        if wb==0:continue
        let wf=count-wb
        if wf==0:break
        sum+=Float64(i)*Float64(hist[i]);let mb=sum/Float64(wb);let mf=(total-sum)/Float64(wf);let variance=Float64(wb)*Float64(wf)*(mb-mf)*(mb-mf)
        if variance>maxv:maxv=variance;threshold=i
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):o[i]=UInt8(if v[i+1]>Int64(threshold):255 else:0)
    return Int64(count)
