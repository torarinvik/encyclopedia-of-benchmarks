from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
from std.math import log2

fn id3_entropy(c0:Int,c1:Int,c2:Int,total:Int)->Float64:
    var h:Float64=0.0
    if c0>0:let p=Float64(c0)/Float64(total);h-=p*log2(p)
    if c1>0:let p=Float64(c1)/Float64(total);h-=p*log2(p)
    if c2>0:let p=Float64(c2)/Float64(total);h-=p*log2(p)
    return h
fn id3_majority(input:UnsafePointer[Float64,ImmutAnyOrigin],ids:List[Int],stride:Int,features:Int)->Int:
    var counts=List[Int](length=3,fill=0);var order=List[Int](capacity=8)
    for i in range(len(ids)):
        let label=Int(input[4+ids[i]*stride+features])
        if counts[label]==0:order.append(label)
        counts[label]+=1
    var chosen=order[0];var best=counts[chosen]
    for i in range(1,len(order)):
        let label=order[i]
        if counts[label]>best:chosen=label;best=counts[label]
    return chosen
fn id3_predict(input:UnsafePointer[Float64,ImmutAnyOrigin],ids:List[Int],stride:Int,features:Int,query:List[Float64],depth:Int,maxdepth:Int,minsplit:Int)->Int:
    let n=len(ids);let majority=id3_majority(input,ids,stride,features)
    if n<minsplit or depth>=maxdepth:return majority
    var distinct_labels=0;var seen_labels=List[Int](length=3,fill=0)
    for i in range(n):
        let label=Int(input[4+ids[i]*stride+features])
        if seen_labels[label]==0:seen_labels[label]=1;distinct_labels+=1
    if distinct_labels<=1:return majority
    var c0=0;var c1=0;var c2=0
    for i in range(n):
        let label=Int(input[4+ids[i]*stride+features])
        if label==0:c0+=1
        elif label==1:c1+=1
        else:c2+=1
    let parent=id3_entropy(c0,c1,c2,n)
    var best_gain:Float64=0.0;var best_feature= -1;var best_threshold:Float64=0.0
    for feature in range(features):
        var present=List[Int](length=33,fill=0)
        for i in range(n):
            let x=input[4+ids[i]*stride+feature]
            let bin=Int((x+4.0)*4.0)
            present[bin]=1
        var prev= -1
        for bin in range(33):
            if present[bin]==0:continue
            if prev>=0:
                let threshold=(Float64(prev-16)+Float64(bin-16))/8.0
                var lc0=0;var lc1=0;var lc2=0;var rc0=0;var rc1=0;var rc2=0
                for i in range(n):
                    let row=ids[i];let label=Int(input[4+row*stride+features])
                    if input[4+row*stride+feature]<threshold:
                        if label==0:lc0+=1
                        elif label==1:lc1+=1
                        else:lc2+=1
                    else:
                        if label==0:rc0+=1
                        elif label==1:rc1+=1
                        else:rc2+=1
                if lc0+lc1+lc2>0 and rc0+rc1+rc2>0:
                    let left_n=lc0+lc1+lc2;let right_n=rc0+rc1+rc2
                    let gain=parent-Float64(left_n)/Float64(n)*id3_entropy(lc0,lc1,lc2,left_n)-Float64(right_n)/Float64(n)*id3_entropy(rc0,rc1,rc2,right_n)
                    if gain>best_gain:best_gain=gain;best_feature=feature;best_threshold=threshold
            prev=bin
    if best_feature<0:return majority
    var left=List[Int](capacity=8);var right=List[Int](capacity=8)
    for i in range(n):
        let row=ids[i]
        if input[4+row*stride+best_feature]<best_threshold:left.append(row)
        else:right.append(row)
    if query[best_feature]<best_threshold:return id3_predict(input,left,stride,features,query,depth+1,maxdepth,minsplit)
    return id3_predict(input,right,stride,features,query,depth+1,maxdepth,minsplit)
@export("decision_tree")
fn decision_tree(input:UnsafePointer[Float64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or length<10 or length>62:return -1
    for i in range(Int(length)):
        let v=input[i]
        if not (v==v) or v>1.0e300 or v< -1.0e300:return -1
    let md=input[0];let ms=input[1];let ns=input[2];let fs=input[3]
    if md<0.0 or md>6.0 or Float64(Int64(md))!=md or ms<2.0 or ms>8.0 or Float64(Int64(ms))!=ms or ns<2.0 or ns>8.0 or Float64(Int64(ns))!=ns or fs<1.0 or fs>4.0 or Float64(Int64(fs))!=fs:return -1
    let maxdepth=Int(md);let minsplit=Int(ms);let samples=Int(ns);let features=Int(fs);let stride=features+1;let qi=4+samples*stride
    if Int(length)<=qi:return -1
    let qv=input[qi]
    if qv<1.0 or qv>4.0 or Float64(Int64(qv))!=qv:return -1
    let nq=Int(qv)
    if length!=c_size_t(qi+1+nq*features):return -1
    for r in range(samples):
        for f in range(features):
            let v=input[4+r*stride+f]
            if v< -4.0 or v>4.0 or Float64(Int64(v*4.0))!=v*4.0:return -1
        let label=input[4+r*stride+features]
        if label<0.0 or label>2.0 or Float64(Int64(label))!=label:return -1
    for i in range(nq*features):
        let v=input[qi+1+i]
        if v< -4.0 or v>4.0 or Float64(Int64(v*4.0))!=v*4.0:return -1
    var staged=List[Float64](capacity=5);staged.append(Float64(nq));var ids=List[Int](capacity=8)
    for r in range(samples):ids.append(r)
    for q in range(nq):
        var query=List[Float64](capacity=4)
        for f in range(features):query.append(input[qi+1+q*features+f])
        staged.append(Float64(id3_predict(input,ids,stride,features,query,0,maxdepth,minsplit)))
    if out==UnsafePointer[Float64,MutAnyOrigin]() or capacity<c_size_t(nq+1):return -2
    for i in range(nq+1):out[i]=staged[i]
    return Int64(nq+1)
