fn p38_pandigital(value_in:Int64)->Bool:
    if value_in<100000000 or value_in>999999999:return False
    var value=value_in;var mask=0
    while value>0:
        let digit=Int(value%10)
        if digit==0 or (mask&(1<<digit))!=0:return False
        mask|=1<<digit;value//=10
    return mask==0x3fe
@export("problem38")
fn problem38(unused:Int64) abi("C")->Int64:
    if unused!=0:return -1
    for base in range(9999,4999,-1):
        let candidate=Int64(100002*base)
        if p38_pandigital(candidate):return candidate
    for base in range(333,99,-1):
        let candidate=Int64(1002003*base)
        if p38_pandigital(candidate):return candidate
    return -1
