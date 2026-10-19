from std.math import isfinite
@export("weight")
fn weight(value:Float64,from:Float64,to:Float64) abi("C")->Float64:
    if not isfinite(value) or value< -1000000.0 or value>1000000.0 or not isfinite(from) or not isfinite(to) or Float64(Int64(from))!=from or Float64(Int64(to))!=to or from<0.0 or from>22.0 or to<0.0 or to>22.0:return -1.0e300
    var factors=InlineArray[Float64,23]()
    factors[0]=1e12;factors[1]=1e9;factors[2]=1000.0;factors[3]=1.0;factors[4]=1e-3;factors[5]=1e-6;factors[6]=1e-9;factors[7]=1e-12;factors[8]=1e-15;factors[9]=1016.0469088;factors[10]=907.18474;factors[11]=50.80234544;factors[12]=12.70058636;factors[13]=6.35029318;factors[14]=0.45359237;factors[15]=0.028349523125;factors[16]=0.0017718451953125;factors[17]=0.00006479891;factors[18]=0.3732417216;factors[19]=0.0311034768;factors[20]=0.00155517384;factors[21]=0.0002;factors[22]=1.66053906660e-27
    return (value*factors[Int(from)])/factors[Int(to)]
