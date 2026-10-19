fn p10_prime(n:Int64)->Bool:
    if n>1 and n<4:return True
    if n<2 or n%2==0 or n%3==0:return False
    var d=Int64(5)
    while d*d<=n:
        if n%d==0 or n%(d+2)==0:return False
        d+=6
    return True
@export("problem10_ruby_prefix")
fn problem10_ruby_prefix(max_total:Int64) abi("C")->Int64:
    if max_total<0 or max_total>2000000:return -1
    var accepted=Int64(1);var value=Int64(1);var n=Int64(2)
    while n<max_total and value<max_total:
        if p10_prime(n):
            value+=n
            if value<max_total:accepted=value
        n+=1
    return accepted
