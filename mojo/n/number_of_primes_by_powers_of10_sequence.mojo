@export("number_of_primes_by_powers_of10_sequence")
fn number_of_primes_by_powers_of10_sequence(index:Int64) abi("C")->Int64:
    if index<0 or index>3:return -1
    if index==0:return 0
    var high=10
    for _ in range(1,Int(index)):high*=10
    var count:Int64=0
    for x in range(2,high):
        var prime=true;var d=2
        while d<=x/d:
            if x%d==0:prime=false;break
            d+=1
        if prime:count+=1
    return count
