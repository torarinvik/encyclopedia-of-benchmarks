@export("julian_easter")
fn julian_easter(year:Int64) abi("C")->Int64:
    if year<1 or year>9999:return -1
    let a=year%4;let b=year%7;let c=year%19;let d=(19*c+15)%30;let e=(2*a+4*b-d+34)%7;let doy=d+e+114;let month=doy//31;let day=doy%31+1
    return year*10000+month*100+day
