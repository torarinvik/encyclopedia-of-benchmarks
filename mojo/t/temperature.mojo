from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import isfinite
@export("temperature")
fn temperature(value:Float64,from:Float64,to:Float64) abi("C")->Float64:
    if not isfinite(value) or not isfinite(from) or not isfinite(to) or value< -1000000.0 or value>1000000.0 or Float64(Int64(from))!=from or Float64(Int64(to))!=to or from<0.0 or from>7.0 or to<0.0 or to>7.0:return -1.0e300
    var kelvin:Float64=0.0
    if from==0.0:kelvin=value
    elif from==1.0:kelvin=value+273.15
    elif from==2.0:kelvin=(value+459.67)*5.0/9.0
    elif from==3.0:kelvin=value*5.0/9.0
    elif from==4.0:kelvin=373.15-value*2.0/3.0
    elif from==5.0:kelvin=value*100.0/33.0+273.15
    elif from==6.0:kelvin=value*5.0/4.0+273.15
    else:kelvin=(value-7.5)*40.0/21.0+273.15
    if to==0.0:return kelvin
    if to==1.0:return kelvin-273.15
    if to==2.0:return kelvin*9.0/5.0-459.67
    if to==3.0:return kelvin*9.0/5.0
    if to==4.0:return (373.15-kelvin)*3.0/2.0
    if to==5.0:return (kelvin-273.15)*33.0/100.0
    if to==6.0:return (kelvin-273.15)*4.0/5.0
    return (kelvin-273.15)*21.0/40.0+7.5
