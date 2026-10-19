from std.math import isfinite, floor, fma
@export("time_conversions")
fn time_conversions(value:Float64,from:Float64,to:Float64) abi("C")->Float64:
    if not isfinite(value) or not isfinite(from) or not isfinite(to) or value<0.0 or value>10000.0 or from<0.0 or from>6.0 or to<0.0 or to>6.0 or Float64(Int64(from))!=from or Float64(Int64(to))!=to:return -1.0e300
    var source:Float64=1.0;var inv:Float64=1.0
    if from==1.0:source=60.0
    elif from==2.0:source=3600.0
    elif from==3.0:source=86400.0
    elif from==4.0:source=604800.0
    elif from==5.0:source=2629800.0
    elif from==6.0:source=31557600.0
    if to==1.0:inv=0.016666666666666666
    elif to==2.0:inv=0.0002777777777777778
    elif to==3.0:inv=0.000011574074074074073
    elif to==4.0:inv=0.0000016534391534391535
    elif to==5.0:inv=0.0000003802570537683474
    elif to==6.0:inv=0.00000003168808781402895
    let scaled=(value*source)*inv;let val=scaled*1000.0;let low=floor(val);let fraction=val-low;let residual=fma(scaled,1000.0,-val)
    var rounded=low
    if fraction>0.5:rounded=low+1.0
    elif fraction==0.5 and (residual>0.0 or (residual==0.0 and Int64(low)%2!=0)):rounded=low+1.0
    return rounded/1000.0
