from std.math import sqrt, floor, ceil
fn p85_tri(side:Int64)->Int64:return side*(side+1)//2
fn p85_abs(a:Int64,b:Int64)->Int64:
    let d=a-b
    return -d if d<0 else d
@export("problem85")
fn problem85(target:Int64) abi("C")->Int64:
    if target<0 or target>2000000000:return -1
    let bound=Int64(ceil(sqrt(Float64(target*2))*1.1));var best=Int64(0);var area=Int64(0);var ta=Int64(0)
    for a in range(1,Int(bound)):
        ta+=Int64(a);let estimate=(-1.0+sqrt(1.0+8.0*Float64(target)/Float64(ta)))/2.0
        let bf=Int64(floor(estimate));let bc=Int64(ceil(estimate));let first=ta*p85_tri(bf);let second=ta*p85_tri(bc)
        if p85_abs(target,first)<p85_abs(target,best):best=first;area=Int64(a)*bf
        if p85_abs(target,second)<p85_abs(target,best):best=second;area=Int64(a)*bc
    return area
