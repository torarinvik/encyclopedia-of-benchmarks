@export("decimal_isolate")
fn decimal_isolate(input:Float64) abi("C")->Float64:
    if not (input>0.0 and input<=999999.0):return -1.0
    let scaled_value=input*10000.0
    let scaled=Int64(scaled_value)
    if Float64(scaled)!=scaled_value or Float64(scaled)/10000.0!=input or scaled%625!=0 or scaled%10000==0:return -1.0
    return Float64(scaled%10000)/10000.0
