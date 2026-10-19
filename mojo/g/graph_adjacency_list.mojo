from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gal_find_vertex(order:InlineArray[Int,32],count:Int,x:Int)->Int:
    for i in range(count):if order[i]==x:return i
    return -1
fn gal_find_neighbor(rows:InlineArray[Int,1088],degree:InlineArray[Int,32],u:Int,x:Int)->Int:
    for i in range(degree[u]):if rows[u*34+i]==x:return i
    return -1
fn gal_del_neighbor(mut rows:InlineArray[Int,1088],mut degree:InlineArray[Int,32],u:Int,at:Int):
    for i in range(at,degree[u]-1):rows[u*34+i]=rows[u*34+i+1]
    degree[u]-=1
fn gal_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt64(8*b))&255)
@export("graph_adjacency_list")
fn graph_adjacency_list(v:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4:return -1
    let direct=Int(v[0]);let n0=Int(v[1]);if (direct!=0 and direct!=1) or n0<0 or n0>32 or length<c_size_t(4+n0):return -1
    var order=InlineArray[Int,32](fill=0);var rows=InlineArray[Int,1088](fill=0);var degree=InlineArray[Int,32](fill=0);var count=n0;var k=2
    for i in range(count):
        let x=v[k];k+=1;if x<0 or x>=32 or gal_find_vertex(order,i,Int(x))>=0:return -1
        order[i]=Int(x)
    let edge_count=Int(v[k]);k+=1;if edge_count<0 or edge_count>1024 or length<c_size_t(k+2*edge_count+1):return -1
    for i in range(edge_count):
        let aa=v[k];let bb=v[k+1];k+=2
        if aa<0 or aa>=32 or bb<0 or bb>=32:return -1
        let a=Int(aa);let b=Int(bb)
        if gal_find_vertex(order,count,a)<0 or gal_find_vertex(order,count,b)<0 or gal_find_neighbor(rows,degree,a,b)>=0:return -1
        rows[a*34+degree[a]]=b;degree[a]+=1
        if direct==0:rows[b*34+degree[b]]=a;degree[b]+=1
    let ops=Int(v[k]);k+=1;if ops<0 or ops>64 or length!=c_size_t(k+3*ops):return -1
    var results=InlineArray[Int64,64](fill=0)
    for oi in range(ops):
        let op=Int(v[k]);let aa=v[k+1];let bb=v[k+2];k+=3
        if op==0:
            if aa<0 or aa>=32 or bb!=0 or gal_find_vertex(order,count,Int(aa))>=0 or count>=32:return -1
            order[count]=Int(aa);degree[Int(aa)]=0;count+=1;results[oi]=1
        elif op==1:
            if aa<0 or aa>=32 or bb!=0:return -1
            let at=gal_find_vertex(order,count,Int(aa));if at<0:return -1
            if direct==1:
                for u in range(count):
                    var found=gal_find_neighbor(rows,degree,order[u],Int(aa))
                    while found>=0:gal_del_neighbor(rows,degree,order[u],found);found=gal_find_neighbor(rows,degree,order[u],Int(aa))
            else:
                let u=Int(aa)
                while degree[u]>0:
                    let neighbor=rows[u*34+degree[u]-1];degree[u]-=1
                    if neighbor!=u:
                        let found=gal_find_neighbor(rows,degree,neighbor,u)
                        if found>=0:gal_del_neighbor(rows,degree,neighbor,found)
            for i in range(at,count-1):order[i]=order[i+1]
            degree[Int(aa)]=0;count-=1;results[oi]=1
        elif op==2 or op==3 or op==5:
            if aa<0 or aa>=32 or bb<0 or bb>=32:return -1
            let a=Int(aa);let b=Int(bb)
            if gal_find_vertex(order,count,a)<0 or gal_find_vertex(order,count,b)<0:return -1
            let found=gal_find_neighbor(rows,degree,a,b)
            if op==5:results[oi]=1 if found>=0 else 0
            elif op==2:
                if found>=0:return -1
                rows[a*34+degree[a]]=b;degree[a]+=1
                if direct==0:rows[b*34+degree[b]]=a;degree[b]+=1
                results[oi]=1
            else:
                if found<0:return -1
                gal_del_neighbor(rows,degree,a,found)
                if direct==0:
                    let reverse=gal_find_neighbor(rows,degree,b,a);if reverse<0:return -1
                    gal_del_neighbor(rows,degree,b,reverse)
                results[oi]=1
        elif op==4:
            if aa<0 or aa>=32 or bb!=0:return -1
            results[oi]=1 if gal_find_vertex(order,count,Int(aa))>=0 else 0
        elif op==6:
            if aa!=0 or bb!=0:return -1
            count=0
            for u in range(32):degree[u]=0
            results[oi]=1
        else:return -1
    var words=2+ops
    for i in range(count):words+=2+degree[i]
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(words*8):return -2
    var pos=0;gal_put(out,pos,Int64(ops));pos+=1
    for i in range(ops):gal_put(out,pos,results[i]);pos+=1
    gal_put(out,pos,Int64(count));pos+=1
    for i in range(count):
        gal_put(out,pos,Int64(order[i]));pos+=1;gal_put(out,pos,Int64(degree[order[i]]));pos+=1
        for j in range(degree[order[i]]):gal_put(out,pos,Int64(rows[order[i]*34+j]));pos+=1
    return Int64(words*8)
