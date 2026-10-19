@export("uniform_numbers")
fn uniform_numbers(value: Int64) abi("C") -> Int64:
    if value < 0 or value > 999999999: return -1
    var remaining=value; var first=Int64(0); var digits=Int64(0)
    while True:
        first=remaining%10; remaining/=10; digits+=1
        if remaining==0: break
    var repeated=Int64(0)
    for _ in range(Int(digits)): repeated=repeated*10+first
    var total=Int64(9)*(digits-1)
    if repeated<=value: total+=first
    else: total+=first-1
    return total
