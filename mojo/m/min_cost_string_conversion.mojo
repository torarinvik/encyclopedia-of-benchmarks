from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mcs_put(out:UnsafePointer[UInt8,MutAnyOrigin],mut p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):out[p]=UInt8((u>>(8*b))&255);p+=1
@export("min_cost_string_conversion")
fn min_cost_string_conversion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>70:return -1
    let sl=v[0]
    if sl<0 or sl>32:return -1
    let src=Int(sl);let dp=1+src
    if dp>=Int(n) or v[dp]<0 or v[dp]>32:return -1
    let dst=Int(v[dp]);let tp=dp+1;let cp=tp+dst
    if Int(n)!=6+src+dst:return -1
    for i in range(src):if v[1+i]<0 or v[1+i]>127:return -1
    for i in range(dst):if v[tp+i]<0 or v[tp+i]>127:return -1
    for i in range(4):if v[cp+i] < -1000 or v[cp+i]>1000:return -1
    let rows=src+1;let cols=dst+1;let cells=rows*cols
    var costs=InlineArray[Int64,1089](fill=0);var codes=InlineArray[Int64,1089](fill=0);var ca=InlineArray[Int64,1089](fill=0);var cb=InlineArray[Int64,1089](fill=0)
    for j in range(1,cols):costs[j]=costs[j-1]+v[cp+3];codes[j]=4;cb[j]=v[tp+j-1]
    for i in range(1,rows):let x=i*cols;costs[x]=costs[x-cols]+v[cp+2];codes[x]=3;ca[x]=v[i]
    for i in range(1,rows):
        for j in range(1,cols):
            let x=i*cols+j;let a=v[i];let b=v[tp+j-1];let same=a==b
            var best=costs[x-cols-1]+(v[cp] if same else v[cp+1]);var op=Int64(1 if same else 2);var aa=a;var bb=Int64(0 if same else b)
            let deletion=costs[x-cols]+v[cp+2]
            if deletion<best:best=deletion;op=3;aa=a;bb=0
            let insertion=costs[x-1]+v[cp+3]
            if insertion<best:best=insertion;op=4;aa=0;bb=b
            costs[x]=best;codes[x]=op;ca[x]=aa;cb[x]=bb
    let bytes=32+cells*32
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var p=0;mcs_put(out,mut p,Int64(rows));mcs_put(out,mut p,Int64(cols))
    for i in range(cells):mcs_put(out,mut p,costs[i])
    mcs_put(out,mut p,Int64(rows));mcs_put(out,mut p,Int64(cols))
    for i in range(cells):mcs_put(out,mut p,codes[i]);mcs_put(out,mut p,ca[i]);mcs_put(out,mut p,cb[i])
    return Int64(bytes)
