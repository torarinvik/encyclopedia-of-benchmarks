from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn glw_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
@export("graph_lua_directed_weighted")
fn graph_lua_directed_weighted(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let nodes=Int(v[0]);let ops=Int(v[1]);if nodes<1 or nodes>16 or ops<0 or ops>63 or n!=c_size_t(2+4*ops):return -1
    var kind=InlineArray[Int,256](fill=0);var weight=InlineArray[Int64,256](fill=0);var rt=InlineArray[Int64,63](fill=0);var rv=InlineArray[Int64,63](fill=0)
    for i in range(ops):
        let op=Int(v[2+4*i]);let a=Int(v[3+4*i]);let b=Int(v[4+4*i]);let value=v[5+4*i]
        if op<0 or op>5 or a<0 or a>=nodes or b<0 or b>=nodes:return -1
        let idx=a*16+b
        if op==0:
            if value< -1000 or value>1000:return -1
            kind[idx]=2;weight[idx]=value;rt[i]= -1
        elif op==1:
            if value!=0:return -1
            kind[idx]=1;weight[idx]=0;rt[i]= -1
        elif op==2:
            if value!=0:return -1
            kind[idx]=0;weight[idx]=0;rt[i]= -1
        elif op==3:
            if value!=0 or kind[idx]!=0:return -1
            kind[idx]=1;weight[idx]=0;rt[i]= -1
        elif op==4:
            if value!=0:return -1
            rt[i]=kind[idx];rv[i]=weight[idx] if kind[idx]==2 else 0
        else:
            if value!=0:return -1
            rt[i]=1 if kind[idx]!=0 else 0
    var edges=0
    for i in range(nodes*nodes):if kind[i]!=0:edges+=1
    let words=2+2*ops+4*edges
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(words*8):return -2
    var pos=0;glw_put(out,pos,Int64(ops));pos+=1
    for i in range(ops):glw_put(out,pos,rt[i]);pos+=1;glw_put(out,pos,rv[i]);pos+=1
    glw_put(out,pos,Int64(edges));pos+=1
    for a in range(nodes):
        for b in range(nodes):
            let idx=a*16+b
            if kind[idx]!=0:glw_put(out,pos,Int64(a));pos+=1;glw_put(out,pos,Int64(b));pos+=1;glw_put(out,pos,Int64(kind[idx]));pos+=1;glw_put(out,pos,weight[idx]);pos+=1
    return Int64(words*8)
