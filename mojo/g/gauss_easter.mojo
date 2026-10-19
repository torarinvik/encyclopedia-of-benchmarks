@export("gauss_easter")
fn gauss_easter(year:Int64) abi("C")->Int64:
    if year<1 or year>9999:return -1
    let a=year%19;let b=year%4;let c=year%7;let century=year//100;let correction=(13+8*century)//25
    var moon=(60-4*correction+3*century)%120;if moon<0:moon+=120
    var start=(16+3*century)%28;if start<0:start+=28
    var days=(76*a+moon)%120;if days<0:days+=120
    var sunday=(8*b+16*c+start+6*days)%28;if sunday<0:sunday+=28
    var month:Int64=0;var day:Int64=0
    if days==116 and sunday==24:month=4;day=19
    elif days==112 and sunday==24:month=4;day=18
    else:
        let marchday=22+(days+sunday)//4
        if marchday<=31:month=3;day=marchday
        else:month=4;day=marchday-31
    return year*10000+month*100+day
