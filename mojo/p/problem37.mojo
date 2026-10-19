fn p37_prime(value:Int64)->Bool:
    if value<2:return False
    if value==2 or value==3:return True
    if value%2==0 or value%3==0:return False
    var d=Int64(5)
    while d<=value//d:
        if value%d==0 or value%(d+2)==0:return False
        d+=6
    return True
fn p37_truncatable(value:Int64)->Bool:
    if !p37_prime(value):return False
    var power=Int64(10)
    while power<value:
        if !p37_prime(value//power) or !p37_prime(value%power):return False
        power*=10
    return True
@export("problem37")
fn problem37(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    var found=0;var sum=Int64(0)
    for candidate in range(13,1000001,2):
        if found>=11:break
        if p37_truncatable(Int64(candidate)):sum+=Int64(candidate);found+=1
    return sum if found==11 else -1
