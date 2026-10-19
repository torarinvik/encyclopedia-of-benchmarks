from std.math import isfinite
@export("weight_conversion")
fn weight_conversion(value:Float64,from:Float64,to:Float64) abi("C")->Float64:
    if not isfinite(value) or value< -1000000.0 or value>1000000.0 or not isfinite(from) or not isfinite(to) or Float64(Int64(from))!=from or Float64(Int64(to))!=to or from<0.0 or from>10.0 or to<0.0 or to>10.0:return -1.0e300
    var dst=InlineArray[Float64,11]();var src=InlineArray[Float64,11]()
    dst[0]=1.0;dst[1]=1000.0;dst[2]=1000000.0;dst[3]=0.001;dst[4]=0.0009842073;dst[5]=0.0011023122;dst[6]=2.2046244202;dst[7]=0.1574731728;dst[8]=35.273990723;dst[9]=5000.0;dst[10]=6.022136652e26
    src[0]=1.0;src[1]=0.001;src[2]=0.000001;src[3]=1000.0;src[4]=1016.04608;src[5]=907.184;src[6]=0.453592;src[7]=6.35029;src[8]=0.0283495;src[9]=0.0002;src[10]=1.660540199e-27
    return (value*dst[Int(to)])*src[Int(from)]
