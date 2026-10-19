fn p70_same_digits(left_in:Int32,right_in:Int32)->Bool:
    var left=left_in;var right=right_in;var counts=InlineArray[Int32,10](fill=0)
    while left!=0:counts[left%10]+=1;left//=10
    while right!=0:counts[right%10]-=1;right//=10
    for d in range(10):if counts[d]!=0:return False
    return True
@export("problem70")
fn problem70(max_n:Int64) abi("C")->Int64:
    if max_n<0 or max_n>10000000:return -1
    let limit=Int(max_n);var prime_flags=InlineArray[Bool,3163](fill=False);var primes=InlineArray[Int32,500](fill=0);var pc=0
    for v in range(2,3163):
        if v<=limit//v:prime_flags[v]=True
    for p in range(2,3163):
        if !prime_flags[p]:continue
        var m=p*p
        while m<3163 and m<=limit//m:prime_flags[m]=False;m+=p
    for v in range(2,3163):
        if v<=limit//v and prime_flags[v]:primes[pc]=Int32(v);pc+=1
    var phi=InlineArray[Int32,32768](fill=0);var rem=InlineArray[Int32,32768](fill=0)
    var bestn=1;var bestphi=Int32(0);var low=0
    while low<=limit:
        var high=low+32767
        if high<low or high>limit:high=limit
        let length=high-low+1
        for off in range(length):phi[off]=Int32(low+off);rem[off]=Int32(low+off)
        for pi in range(pc):
            let prime=Int(primes[pi]);var first=low+(prime-low%prime)%prime
            if first<prime:first=prime
            var multiple=first
            while multiple<=high:
                let off=multiple-low;phi[off]-=phi[off]//Int32(prime)
                while rem[off]%Int32(prime)==0:rem[off]//=Int32(prime)
                if high-multiple<prime:break
                multiple+=prime
        for off in range(length):
            if rem[off]>1:phi[off]-=phi[off]//rem[off]
            let number=low+off
            if number<2:continue
            if Int64(number)*Int64(bestphi)<Int64(bestn)*Int64(phi[off]) and p70_same_digits(Int32(number),phi[off]):
                bestn=number;bestphi=phi[off]
        if high==limit:break
        low=high+1
    return Int64(bestn)
