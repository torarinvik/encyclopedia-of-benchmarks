from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
from std.math import abs, isfinite, sqrt, trunc

fn mean_shift_dist(a:InlineArray[Float64,48],ai:Int,b:InlineArray[Float64,48],bi:Int,d:Int)->Float64:
    var sum=0.0
    for k in range(d):let diff=a[ai*d+k]-b[bi*d+k];sum+=diff*diff
    return sqrt(sum)
fn mean_shift_near(a:Float64,b:Float64)->Bool:return abs(a-b)<1.0e-6

@export("mean_shift")
fn mean_shift(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<5 or n>54:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    let nv=v[0];let dv=v[1];let bandwidth=v[2];let iv=v[3];let tol=v[4]
    if trunc(nv)!=nv or trunc(dv)!=dv or trunc(iv)!=iv or nv<1 or nv>16 or dv<1 or dv>3 or iv<1 or iv>64 or bandwidth<0.5 or bandwidth>20.0 or tol<1.0e-5 or tol>1.0e-2:return -1
    let count=Int(nv);let d=Int(dv);let iterations=Int(iv)
    if n!=c_size_t(5+count*d):return -1
    var data=InlineArray[Float64,48](fill=0.0);var candidates=InlineArray[Float64,48](fill=0.0);var next=InlineArray[Float64,48](fill=0.0)
    for i in range(count*d):
        let x=v[i+5];if x< -10.0 or x>10.0:return -1
        data[i]=x;candidates[i]=x
    for _ in range(iterations):
        for c in range(count):
            var sums=InlineArray[Float64,3](fill=0.0);var neighbors=0
            for p in range(count):
                let distance=mean_shift_dist(data,p,candidates,c,d)
                if mean_shift_near(distance,bandwidth):return -1
                if distance<=bandwidth:
                    neighbors+=1
                    for k in range(d):sums[k]+=data[p*d+k]
            for k in range(d):next[c*d+k]=candidates[c*d+k] if neighbors==0 else sums[k]/Float64(neighbors)
        var all_converged=True
        for c in range(count):
            let movement=mean_shift_dist(candidates,c,next,c,d)
            if mean_shift_near(movement,tol):return -1
            if movement>=tol:all_converged=False;break
        if all_converged:break
        for i in range(count*d):candidates[i]=next[i]
    var centroids=InlineArray[Float64,48](fill=0.0);var centroid_count=0
    for c in range(count):
        var keep=True
        for existing in range(centroid_count):
            let distance=mean_shift_dist(candidates,c,centroids,existing,d)
            if mean_shift_near(distance,bandwidth):return -1
            if distance<bandwidth:keep=False;break
        if keep:
            for k in range(d):centroids[centroid_count*d+k]=candidates[c*d+k]
            centroid_count+=1
    var labels=InlineArray[Float64,16](fill=0.0)
    for p in range(count):
        var best_index=0;var best_distance=mean_shift_dist(data,p,centroids,0,d)
        for c in range(1,centroid_count):
            let distance=mean_shift_dist(data,p,centroids,c,d)
            if distance!=best_distance and mean_shift_near(distance,best_distance):return -1
            if distance<best_distance:best_index=c;best_distance=distance
        labels[p]=Float64(best_index)
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):out[i]=labels[i]
    return Int64(count)
