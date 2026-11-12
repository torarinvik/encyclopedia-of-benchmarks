fn integer_sqrt(value:Int64)->Int64:
    var low:Int64=1;var high:Int64=1000000
    while low<high:
        let middle=low+(high-low+1)//2
        if middle<=value//middle:low=middle
        else:high=middle-1
    return low

@export("counting_squarefrees")
fn counting_squarefrees(n:Int64) abi("C")->Int64:
    if n<1 or n>1000000000000:return -1
    let limit=Int(integer_sqrt(n))
    var mobius=InlineArray[UInt8,1000001](fill=0)
    var composite=InlineArray[Bool,1000001](fill=False)
    for value in range(1,limit+1):mobius[value]=1
    for prime in range(2,limit+1):
        if composite[prime]:continue
        if prime<=limit//prime:
            for multiple in range(prime*prime,limit+1,prime):composite[multiple]=True
        for multiple in range(prime,limit+1,prime):
            if mobius[multiple]==1:mobius[multiple]=2
            elif mobius[multiple]==2:mobius[multiple]=1
        if prime<=limit//prime:
            let square=prime*prime
            for multiple in range(square,limit+1,square):mobius[multiple]=0
    var count:Int64=0
    for divisor in range(1,limit+1):
        let d=Int64(divisor)
        let quotient=n//(d*d)
        if mobius[divisor]==1:count+=quotient
        elif mobius[divisor]==2:count-=quotient
    return count
