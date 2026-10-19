fn p78_mod(value:Int64,modulus:Int64)->Int64:
    let rem=value%modulus
    return rem+modulus if rem<0 else rem
@export("problem78")
fn problem78(modulus:Int64) abi("C")->Int64:
    if modulus<1 or modulus>1000000:return -1
    var parts=InlineArray[Int32,55375](fill=0);parts[0]=1
    for n in range(1,55375):
        var value=Int64(0);var j=1
        while True:
            let first=(3*j*j-j)//2
            if first>n:break
            let sign=Int64(-1) if j%2==0 else Int64(1)
            value=p78_mod(value+sign*Int64(parts[n-first]),modulus)
            let second=first+j
            if second>n:break
            value=p78_mod(value+sign*Int64(parts[n-second]),modulus);j+=1
        if value==0:return Int64(n)
        parts[n]=Int32(value)
    return -1
