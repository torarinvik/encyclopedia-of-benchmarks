fn p686_round_part(exponent:Int64)->Float64:
    let logarithm=0.30102999566398114*Float64(exponent);let integer=Int64(logarithm);let diff=logarithm-Float64(integer);let scaled=diff*1000000000000000.0
    var rounded=Int64(scaled);let rem=scaled-Float64(rounded)
    if rem>0.5 or (rem==0.5 and rounded%2!=0):rounded+=1
    return Float64(rounded)/1000000000000000.0
@export("problem686")
fn problem686(number:Int64) abi("C")->Int64:
    if number<1 or number>678910:return -1
    var power=Int64(90);var position=Int64(0);var previous=Int64(0)
    while position<number:
        let difference=p686_round_part(power)
        if difference>=0.09342168516223506:power+=93
        elif difference<0.08990511143939792:power+=196
        else:previous=power;power+=196;position+=1
    return previous
