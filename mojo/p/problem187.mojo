@export("problem187")
fn problem187(max_number:Int64) abi("C")->Int64:
    if max_number<0 or max_number>100000000:return -1
    let prime_limit=max_number//2
    if prime_limit<=2:return 0
    let words=Int((prime_limit+63)//64)
    var bits=InlineArray[UInt64,781251](fill=0)
    bits[0]|=UInt64(3)
    for p in range(2,Int((prime_limit-1)//2+1)):
        if ((bits[p//64]>>(p%64))&1)!=0:continue
        if Int64(p)<= (prime_limit-1)//Int64(p):
            var m=p*p
            while Int64(m)<prime_limit:
                bits[m//64]|=UInt64(1)<<(m%64);m+=p
    var right=Int(prime_limit-1)
    while right>=2 and ((bits[right//64]>>(right%64))&1)!=0:right-=1
    if right<2:return 0
    var pc=0
    for x in range(2,right+1):if ((bits[x//64]>>(x%64))&1)==0:pc+=1
    var rank=pc-1;var left_rank=0;var count=Int64(0)
    for left in range(2,right+1):
        if ((bits[left//64]>>(left%64))&1)!=0:continue
        if left>right:break
        while rank>=left_rank and Int64(left)*Int64(right)>=max_number:
            rank-=1;right-=1
            while right>=2 and ((bits[right//64]>>(right%64))&1)!=0:right-=1
        if rank<left_rank:break
        count+=Int64(rank-left_rank+1);left_rank+=1
    return count
