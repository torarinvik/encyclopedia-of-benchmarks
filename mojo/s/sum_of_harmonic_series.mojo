from std.math import isfinite
comptime INVALID_HARMONIC:Float64= -1.0e300
@export("sum_of_harmonic_series")
fn sum_of_harmonic_series(first:Float64,difference:Float64,terms:Float64) abi("C")->Float64:
    if not isfinite(first) or not isfinite(difference) or not isfinite(terms) or first<=0.0 or first>1000.0 or difference<0.0 or difference>1000.0 or terms<1.0 or terms>256.0 or Float64(Int(terms))!=terms:return INVALID_HARMONIC
    let count=Int(terms);var arithmetic_term=1.0/first;var total=0.0
    for index in range(count):
        total+=1.0/arithmetic_term
        if index+1<count:arithmetic_term+=difference
    return total
