from std.math import log2
@export("problem800")
fn problem800(base:Int64,degree:Int64) abi("C")->Int64:
    if base<2 or base>1000000 or degree<1 or degree>1000000:return -1
    let upper=Float64(degree)*log2(Float64(base));let prime_limit=Int64(upper)
    if prime_limit<=2:return 0
    var bits=InlineArray[UInt64,311000](fill=0)
    for prime in range(2,Int((prime_limit-1)//2+1)):
        if ((bits[prime//64]>>(prime%64))&1)!=0:continue
        if Int64(prime)<=(prime_limit-1)//Int64(prime):
            var multiple=prime*prime
            while Int64(multiple)<prime_limit:bits[multiple//64]|=UInt64(1)<<(multiple%64);multiple+=prime
    var right=Int64(0);var pc=Int64(0)
    for value in range(2,Int(prime_limit)):
        if ((bits[value//64]>>(value%64))&1)==0:right=Int64(value);pc+=1
    if pc<2:return 0
    var rank=pc-1;var left_rank=Int64(0);var left=Int64(2);var count=Int64(0)
    while left_rank<rank:
        while ((bits[Int(left)//64]>>(Int(left)%64))&1)!=0:left+=1
        let log_left=log2(Float64(left))
        while Float64(right)*log_left+Float64(left)*log2(Float64(right))>upper:
            rank-=1;right-=1
            while right>=2 and ((bits[Int(right)//64]>>(Int(right)%64))&1)!=0:right-=1
        count+=rank-left_rank;left_rank+=1;left+=1
    return count
