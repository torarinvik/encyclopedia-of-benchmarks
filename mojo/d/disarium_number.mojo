@export("disarium_number")
fn disarium_number(number:Int64) abi("C")->Int64:
    if number<1 or number>99999999:return -1
    var digits=0;var n=number
    while n>0:digits+=1;n/=10
    var position=digits;var remaining=number;var total:Int64=0
    while remaining>0:
        let digit=remaining%10;var power:Int64=1
        for i in range(position):power*=digit
        total+=power;position-=1;remaining/=10
    return 1 if total==number else 0
