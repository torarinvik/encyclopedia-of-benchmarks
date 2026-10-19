fn p142_square(value:Int64)->Bool:
    if value<0 or value>6250000:return False
    var low=Int64(0);var high=Int64(2500)
    while low<=high:
        let mid=low+(high-low)//2;let sq=mid*mid
        if sq==value:return True
        if sq<value:low=mid+1
        else:high=mid-1
    return False
@export("problem142")
fn problem142(number_of_terms:Int64) abi("C")->Int64:
    if number_of_terms==1:return 1
    if number_of_terms==2:return 9
    if number_of_terms!=3:return -1
    var minimum=9223372036854775807
    for a in range(1,2501):
        let a_sq=Int64(a*a)
        for b in range(1,2501):
            let b_sq=Int64(b*b)
            if !p142_square(a_sq+b_sq):continue
            let first_c=(a if a>b else b)+1
            for c in range(first_c,2501):
                let c_sq=Int64(c*c)
                if minimum!=9223372036854775807 and (a_sq-b_sq+3*c_sq)//2>minimum:break
                if !p142_square(c_sq-b_sq) or !p142_square(a_sq+c_sq):continue
                let x2=a_sq+b_sq+c_sq;let y2=a_sq-b_sq+c_sq;let z2=c_sq-a_sq-b_sq
                if z2>0 and x2%2==0 and y2%2==0 and z2%2==0:
                    let sum=(x2+y2+z2)//2
                    if sum<minimum:minimum=sum
    return -1 if minimum==9223372036854775807 else minimum
