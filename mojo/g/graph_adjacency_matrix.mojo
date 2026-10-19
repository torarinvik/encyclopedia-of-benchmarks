from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gam_find(vertices:InlineArray[Int,8],count:Int,x:Int)->Int:
    for i in range(count):if vertices[i]==x:return i
    return -1
fn gam_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
@export("graph_adjacency_matrix")
fn graph_adjacency_matrix(v:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4:return -1
    let direct=Int(v[0]);let n0=Int(v[1]);if (direct!=0 and direct!=1) or n0<0 or n0>8 or length<c_size_t(3+n0):return -1
    var ids=InlineArray[Int,8](fill=0);var mat=InlineArray[UInt8,64](fill=0);var count=n0;var k=2
    for i in range(count):
        let x=v[k];k+=1;if x<0 or x>=32 or gam_find(ids,i,Int(x))>=0:return -1
        ids[i]=Int(x)
    let edges=Int(v[k]);k+=1;if edges<0 or edges>64 or length<c_size_t(k+2*edges+1):return -1
    for e in range(edges):
        let aa=v[k];let bb=v[k+1];k+=2;if aa<0 or aa>=32 or bb<0 or bb>=32:return -1
        let a=gam_find(ids,count,Int(aa));let b=gam_find(ids,count,Int(bb))
        if a<0 or b<0 or mat[a*8+b]!=0:return -1
        mat[a*8+b]=1
        if direct==0:mat[b*8+a]=1
    let ops=Int(v[k]);k+=1;if ops<0 or ops>24 or length!=c_size_t(k+3*ops):return -1
    var results=InlineArray[Int64,24](fill=0)
    for oi in range(ops):
        let op=Int(v[k]);let aa=v[k+1];let bb=v[k+2];k+=3
        if op==0:
            if aa<0 or aa>=32 or bb!=0 or gam_find(ids,count,Int(aa))>=0 or count>=8:return -1
            for i in range(8):mat[i*8+count]=0;mat[count*8+i]=0
            ids[count]=Int(aa);count+=1;results[oi]=1
        elif op==1:
            if aa<0 or aa>=32 or bb!=0:return -1
            let removed=gam_find(ids,count,Int(aa));if removed<0:return -1
            for r in range(removed,count-1):
                ids[r]=ids[r+1]
                for c in range(count):mat[r*8+c]=mat[(r+1)*8+c]
            for r in range(count-1):
                for c in range(removed,count-1):mat[r*8+c]=mat[r*8+c+1]
            count-=1
            for i in range(8):mat[(count)*8+i]=0;mat[i*8+count]=0
            results[oi]=1
        elif op==2 or op==3 or op==5:
            if aa<0 or aa>=32 or bb<0 or bb>=32:return -1
            let a=gam_find(ids,count,Int(aa));let b=gam_find(ids,count,Int(bb));if a<0 or b<0:return -1
            let present=mat[a*8+b]!=0
            if op==5:results[oi]=1 if present else 0
            elif op==2:
                if present:return -1
                mat[a*8+b]=1
                if direct==0:mat[b*8+a]=1
                results[oi]=1
            else:
                if not present:return -1
                mat[a*8+b]=0
                if direct==0:mat[b*8+a]=0
                results[oi]=1
        elif op==4:
            if aa<0 or aa>=32 or bb!=0:return -1
            results[oi]=1 if gam_find(ids,count,Int(aa))>=0 else 0
        elif op==6:
            if aa!=0 or bb!=0:return -1
            count=0
            for i in range(64):mat[i]=0
            results[oi]=1
        else:return -1
    let words=2+ops+count+count*count
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(words*8):return -2
    var pos=0;gam_put(out,pos,Int64(ops));pos+=1
    for i in range(ops):gam_put(out,pos,results[i]);pos+=1
    gam_put(out,pos,Int64(count));pos+=1
    for i in range(count):gam_put(out,pos,Int64(ids[i]));pos+=1
    for i in range(count):
        for j in range(count):gam_put(out,pos,Int64(mat[i*8+j]));pos+=1
    return Int64(words*8)
