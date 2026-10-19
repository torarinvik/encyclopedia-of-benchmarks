@export("recursive_digit_sum")
fn recursive_digit_sum(number:Int64,repetitions:Int64) abi("C")->Int64:
    if number<0 or repetitions<0 or repetitions>1000000:return -1
    var x=number;var sum:Int64=0
    while True:sum+=x%10;x/=10;if x==0:break
    var total=sum*repetitions
    while total>=10:
        var next:Int64=0
        while True:next+=total%10;total/=10;if total==0:break
        total=next
    return total
