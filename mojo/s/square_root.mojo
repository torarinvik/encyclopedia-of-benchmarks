@export("square_root")
fn square_root(x:Float64) abi("C")->Float64:
    if x==0.0:return 0.0
    var estimate=if x>=1.0 then x else 1.0
    for _ in range(1100):
        let next=0.5*estimate+0.5*(x/estimate)
        if next>=estimate:return estimate
        estimate=next
    return estimate
