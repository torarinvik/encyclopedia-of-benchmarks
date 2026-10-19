from std.math import isfinite
comptime BAD:Float64= -1.0e300
@export("standard_score")
fn standard_score(value:Float64,mean:Float64,stddev:Float64) abi("C")->Float64:
    if not isfinite(value) or not isfinite(mean) or not isfinite(stddev) or value< -1000000 or value>1000000 or mean< -1000000 or mean>1000000 or stddev==0.0 or abs(stddev)>1000000 or abs(stddev)<1e-6:return BAD
    return (value-mean)/stddev
