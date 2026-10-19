fn pig_mix(h:UInt32,b:UInt8)->UInt32:return (h^UInt32(b))*16777619
@export("pi_generator")
fn pi_generator(digits:Int64) abi("C")->Int64:
    if digits<0 or digits>8:return -1
    var q:Int64=1;var r:Int64=0;var t:Int64=1;var k:Int64=1;var n:Int64=3;var m:Int64=3;var counter=0;var h:UInt32=2166136261
    while counter!=Int(digits)+1:
        if 4*q+r-t<n*t:
            h=pig_mix(h,UInt8(48+n))
            if counter==0:h=pig_mix(h,46)
            if digits==counter:break
            counter+=1;let nr=10*(r-n*t);n=(10*(3*q+r))/t-10*n;q*=10;r=nr
        else:
            let nr=(2*q+r)*m;let nn=(q*(7*k)+2+(r*m))/(t*m);q*=k;t*=m;m+=2;k+=1;n=nn;r=nr
    return Int64(h)
