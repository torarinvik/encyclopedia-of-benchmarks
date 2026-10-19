from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List

fn reg_mean(y:List[Float64],start:Int,end:Int)->Float64:
    var total:Float64=0.0
    for i in range(start,end):total+=y[i]
    return total/Float64(end-start)
fn reg_mse(a:List[Float64],start:Int,end:Int,mean:Float64)->Float64:
    var total:Float64=0.0
    for i in range(start,end):let delta=a[i]-mean;total+=delta*delta
    return total/Float64(end-start)
fn reg_predict(x:List[Float64],y:List[Float64],start:Int,end:Int,minleaf:Int,depth:Int,q:Float64)->Float64:
    let mean=reg_mean(y,start,end);let count=end-start
    if count<2*minleaf or depth==1:return mean
    var best_error=2.0*reg_mse(x,start,end,mean);var best_split=0
    for split in range(count+1):
        let right_count=count-split
        if split<minleaf or right_count<minleaf:continue
        let left_mean=reg_mean(y,start,start+split);let right_mean=reg_mean(y,start+split,end)
        let error=reg_mse(x,start,start+split,left_mean)+reg_mse(x,start+split,end,right_mean)
        if error<best_error:best_error=error;best_split=split
    if best_split==0:return mean
    let boundary=x[start+best_split]
    if q>=boundary:return reg_predict(x,y,start+best_split,end,minleaf,depth-1,q)
    return reg_predict(x,y,start,start+best_split,minleaf,depth-1,q)
@export("decision_tree_python_regression")
fn decision_tree_python_regression(input:UnsafePointer[Float64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or length<8 or length>41:return -1
    for i in range(Int(length)):
        let v=input[i]
        if not (v==v) or v>1.0e300 or v< -1.0e300:return -1
    let depthv=input[0];let minv=input[1];let samplesv=input[2]
    if depthv<1.0 or depthv>6.0 or Float64(Int64(depthv))!=depthv or minv<1.0 or minv>6.0 or Float64(Int64(minv))!=minv or samplesv<2.0 or samplesv>12.0 or Float64(Int64(samplesv))!=samplesv:return -1
    let depth=Int(depthv);let minleaf=Int(minv);let samples=Int(samplesv);let qi=3+2*samples
    if Int(length)<=qi:return -1
    let qv=input[qi]
    if qv<1.0 or qv>12.0 or Float64(Int64(qv))!=qv:return -1
    let nq=Int(qv)
    if length!=c_size_t(qi+1+nq) or length>40:return -1
    var x=List[Float64](capacity=12);var y=List[Float64](capacity=12)
    for i in range(samples):
        let xv=input[3+i];let yv=input[3+samples+i]
        if xv< -8.0 or xv>8.0 or Float64(Int64(xv))!=xv or yv< -8.0 or yv>8.0 or Float64(Int64(yv))!=yv:return -1
        x.append(xv);y.append(yv)
    var queries=List[Float64](capacity=12)
    for i in range(nq):
        let v=input[qi+1+i]
        if v< -8.0 or v>8.0 or Float64(Int64(v))!=v:return -1
        queries.append(v)
    var staged=List[Float64](capacity=13);staged.append(Float64(nq))
    for i in range(nq):staged.append(reg_predict(x,y,0,samples,minleaf,depth,queries[i]))
    if out==UnsafePointer[Float64,MutAnyOrigin]() or capacity<c_size_t(nq+1):return -2
    for i in range(nq+1):out[i]=staged[i]
    return Int64(nq+1)
