from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
fn jv_orient(ax:Int64,ay:Int64,bx:Int64,by:Int64,cx:Int64,cy:Int64)->Int64:return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
fn jv_put(o:UnsafePointer[UInt8,MutAnyOrigin],w:Int,x:Int64):
    let b=bitcast[UInt64](x)
    for i in range(8):o[w*8+i]=UInt8((b>>UInt64(8*i))&255)
@export("jarvis_scan")
fn jarvis_scan(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>64:return -1
    let count=Int(v[0]);if n!=c_size_t(1+2*count):return -1
    var x=InlineArray[Int64,64](fill=0);var y=InlineArray[Int64,64](fill=0)
    for i in range(count):x[i]=v[1+2*i];y[i]=v[2+2*i];if x[i]< -10000 or x[i]>10000 or y[i]< -10000 or y[i]>10000:return -1
    if count<=2:return 0
    for i in range(count):
        for j in range(i+1,count):if x[i]==x[j] and y[i]==y[j]:return -1
    for i in range(count):
        for j in range(i+1,count):
            for k in range(j+1,count):if jv_orient(x[i],y[i],x[j],y[j],x[k],y[k])==0:return -1
    var start=0
    for i in range(1,count):if x[i]<x[start] or (x[i]==x[start] and y[i]<y[start]):start=i
    var hull=InlineArray[Int,64](fill=0);var hc=0;var cur=start
    while True:
        if hc==count:return -1
        hull[hc]=cur;hc+=1;var cand=(cur+1)%count
        for p in range(count):if jv_orient(x[cur],y[cur],x[p],y[p],x[cand],y[cand])>0:cand=p
        if cand==start:break
        cur=cand
    let bytes=hc*16
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(hc):jv_put(o,2*i,x[hull[i]]);jv_put(o,2*i+1,y[hull[i]])
    return Int64(bytes)
