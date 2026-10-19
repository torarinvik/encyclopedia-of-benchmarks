@export("number_of_primes_by_number_of_digits_sequence")
fn number_of_primes_by_number_of_digits_sequence(index:Int64) abi("C")->Int64:
    if index<0 or index>3:return -1
    if index==0:return 0
    var low:Int64=1;var high:Int64=10
    for _ in range(1,Int(index)):low=high;high*=10
    var count:Int64=0
    for x in range(Int(low+1),Int(high)+1):
        var prime=true
        var d=2
        while d*d<=x:
            if x%d==0:prime=false;break
            d+=1
        if prime:count+=1
    return count
