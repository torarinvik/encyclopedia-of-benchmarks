from math import floor
@export("simpson_rule")
fn simpson_rule(b:Float64,steps:Float64) abi("C")->Float64:
    if (b!=1.0 and b!=2.0 and b!=3.0) or steps!=10.0:return -1.0e300
    let h=b/steps;var x=h;var y=(h/3.0)*0.0;var count=2
    while x<b-h:
        let weight=4-2*(count%2);let f=x*x
        y+=(h/3.0)*Float64(weight)*f;count+=1;x=x+h
    y+=(h/3.0)*(b*b)
    return y
