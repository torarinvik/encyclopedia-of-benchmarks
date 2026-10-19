from std.math import floor
fn p493_choose(n:Int,k:Int)->Float64:
    if k<0 or k>n:return 0.0
    let r=k if k<n-k else n-k;var value=Float64(1.0)
    for i in range(1,r+1):value=value*Float64(n-r+i)/Float64(i)
    return value
@export("problem493")
fn problem493(picks:Int64) abi("C")->Int64:
    if picks<0 or picks>70:return -1
    let absent=0.0 if picks>60 else p493_choose(70-Int(picks),10)/p493_choose(70,10)
    let scaled=7.0*(1.0-absent)*1000000000.0;let base=floor(scaled);let fraction=scaled-base;var rounded=Int64(base)
    if fraction>0.5 or (fraction==0.5 and rounded%2!=0):rounded+=1
    return rounded
