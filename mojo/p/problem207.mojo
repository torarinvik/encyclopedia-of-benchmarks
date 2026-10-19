from std.math import isfinite
@export("problem207")
fn problem207(max_proportion:Float64) abi("C")->Float64:
    let invalid=Float64(-1.0e300)
    if !isfinite(max_proportion) or max_proportion<1.0e-5 or max_proportion>1.0:return invalid
    var partitions=Int64(0);var perfect=Int64(0)
    while partitions<5000000:
        partitions+=1;let candidate=partitions*(partitions+1);let v=partitions+1
        if v>0 and (v&(v-1))==0:perfect+=1
        if Float64(perfect)/Float64(partitions)<max_proportion:return Float64(candidate)
    return invalid
