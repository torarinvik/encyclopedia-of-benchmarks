from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gcent_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
@export("graph_centrality")
fn graph_centrality(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let count=Int(v[0]);let edges=Int(v[1]);if count<1 or count>16 or edges<0 or edges>count*(count-1) or n!=c_size_t(2+3*edges):return -1
    var d=InlineArray[Int64,256](fill=0);let inf=Int64(9223372036854775807)
    for i in range(count):
        for j in range(count):d[i*16+j]=inf if i!=j else 0
    for e in range(edges):
        let a=v[2+3*e];let b=v[3+3*e];let w=v[4+3*e]
        if a<0 or a>=count or b<0 or b>=count or a==b or w<1 or w>1000000 or d[Int(a)*16+Int(b)]!=inf:return -1
        d[Int(a)*16+Int(b)]=w
    for k in range(count):
        for i in range(count):
            if d[i*16+k]!=inf:
                for j in range(count):
                    if d[k*16+j]!=inf and d[i*16+k]+d[k*16+j]<d[i*16+j]:d[i*16+j]=d[i*16+k]+d[k*16+j]
    var central:Int64= -1;var median:Int64= -1;var best_e=inf;var best_h= -1.0
    if count==1:central=0;median=0
    else:
        for i in range(count):
            var reachable=0;var ecc:Int64=0;var harmonic=0.0
            for j in range(count):
                if i!=j and d[i*16+j]!=inf:
                    reachable+=1
                    if d[i*16+j]>ecc:ecc=d[i*16+j]
                    harmonic+=1.0/Float64(d[i*16+j])
            if reachable>0 and ecc<best_e:best_e=ecc;central=Int64(i)
            if reachable>0 and harmonic>best_h:best_h=harmonic;median=Int64(i)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    gcent_put(out,0,central);gcent_put(out,1,median);return 16
