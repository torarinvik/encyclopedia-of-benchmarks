@export("problem77")
fn problem77(threshold:Int64) abi("C")->Int64:
    if threshold<0 or threshold>100000:return -1
    var ways=InlineArray[Int64,100](fill=0);ways[0]=1
    for prime in range(2,100):
        var isprime=True
        for d in range(2,prime):
            if d*d>prime:break
            if prime%d==0:isprime=False;break
        if isprime:
            for total in range(prime,100):ways[total]+=ways[total-prime]
    for value in range(1,100):if ways[value]>threshold:return Int64(value)
    return -1
