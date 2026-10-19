from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gper_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
@export("graph_peripherality")
fn graph_peripherality(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let count=Int(v[0]);let edges=Int(v[1]);if count<1 or count>8 or edges<0 or edges>56 or edges>count*(count-1) or n!=c_size_t(2+3*edges):return -1
    let inf=Int64(2305843009213693951);var d=InlineArray[Int64,64](fill=inf)
    for i in range(count):d[i*8+i]=0
    for e in range(edges):
        let a=v[2+3*e];let b=v[3+3*e];let w=v[4+3*e]
        if a<0 or a>=count or b<0 or b>=count or a==b or w<1 or w>1000000 or d[Int(a)*8+Int(b)]!=inf:return -1
        d[Int(a)*8+Int(b)]=w
    for k in range(count):
        for i in range(count):
            if d[i*8+k]!=inf:
                for j in range(count):if d[k*8+j]!=inf and d[i*8+k]+d[k*8+j]<d[i*8+j]:d[i*8+j]=d[i*8+k]+d[k*8+j]
    if count>1:
        for i in range(count):
            for j in range(count):if i!=j and d[i*8+j]==inf:return -1
    var peripheral= -1;var far= -1;var best_e:Int64= -1;var best_f:Int64= -1;var any=False
    if count==1:peripheral=0;far=0;best_e=0;best_f=0
    else:
        for s in range(count):
            var found=False;var ecc:Int64=0;var farness:Int64=0
            for t in range(count):
                let val=d[s*8+t]
                if t!=s and val!=inf and val!=0:
                    found=True
                    if val>ecc:ecc=val
                    farness+=val
            if found:any=True
            if peripheral<0 or (found and (best_e<0 or ecc>best_e or (ecc==best_e and s<peripheral))):peripheral=s;best_e=ecc
            if far<0 or (found and (best_f<0 or farness>best_f or (farness==best_f and s<far))):far=s;best_f=farness
        if not any:peripheral= -1;far= -1;best_e= -1;best_f= -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<32:return -2
    gper_put(out,0,Int64(peripheral));gper_put(out,1,best_e);gper_put(out,2,Int64(far));gper_put(out,3,best_f);return 32
