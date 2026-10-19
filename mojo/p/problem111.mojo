fn p111_is_prime(value:Int64,sieve_limit:Int64)->Bool:
    if value<2:return False
    if value<=sieve_limit:return False
    if value%2==0:return False
    var divisor=Int64(3)
    while divisor<=value//divisor:
        if value%divisor==0:return False
        divisor+=2
    return True
@export("problem111")
fn problem111(n:Int64) abi("C")->Int64:
    if n<1000 or n>10000000000:return -1
    var root=Int64(0)
    while root+1<=n//(root+1):root+=1
    let sieve_limit=root+1
    var copy=n;var digits=0
    while copy>0:digits+=1;copy//=10
    let width=digits-1
    let repeated_two=width-2
    var total=Int64(0)
    for i in range(1,10):
        for j in range(1,10):
            var value=Int64(i)
            for z in range(width-2):value*=10
            value=value*10+Int64(j)
            if p111_is_prime(value,sieve_limit):total+=value
    var one_digit=InlineArray[Bool,10](fill=False)
    for i in range(1,10):
        for j in range(width):
            for k in range(10):
                var value=Int64(0)
                for position in range(width):
                    value=value*10+Int64(k if position==j else i)
                if p111_is_prime(value,sieve_limit):one_digit[i]=True;total+=value
    for i in range(1,10):
        if !one_digit[i]:
            for j in range(repeated_two+1):
                for k in range(repeated_two-j+1):
                    for m1 in range(10):
                        if m1==0 and j==0:continue
                        for m2 in range(10):
                            var value=Int64(0)
                            for position in range(width):
                                var digit=i
                                if position==j:digit=m1
                                elif position==j+k+1:digit=m2
                                value=value*10+Int64(digit)
                            if p111_is_prime(value,sieve_limit):total+=value
    return total
