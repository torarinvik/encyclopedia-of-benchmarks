fn p34_fact_digit(d:Int64)->Int64:
    if d<2:return 1
    if d==2:return 2
    if d==3:return 6
    if d==4:return 24
    if d==5:return 120
    if d==6:return 720
    if d==7:return 5040
    if d==8:return 40320
    return 362880
@export("problem34")
fn problem34(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    var total=Int64(0)
    for number in range(3,2540161):
        var remaining=Int64(number);var sum=Int64(0)
        while remaining>0:sum+=p34_fact_digit(remaining%10);remaining//=10
        if sum==Int64(number):total+=Int64(number)
    return total
