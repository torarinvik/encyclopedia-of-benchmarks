@export("problem164")
fn problem164(n_digits:Int64) abi("C")->Int64:
    if n_digits<0 or n_digits>26:return -1
    if n_digits==0:return 1
    var current=InlineArray[Int64,100](fill=0);var next=InlineArray[Int64,100](fill=0)
    for first in range(1,10):current[first*10]=1
    for used in range(1,Int(n_digits)):
        for index in range(100):next[index]=0
        for previous in range(10):
            for before in range(10):
                let ways=current[previous*10+before];let maxdigit=9-previous-before
                for digit in range(maxdigit+1):next[digit*10+previous]+=ways
        for index in range(100):current[index]=next[index]
    var total=Int64(0)
    for index in range(100):total+=current[index]
    return total
