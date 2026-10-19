fn p180_gcd(left_in:Int64,right_in:Int64)->Int64:
    var left=left_in;var right=right_in
    while right!=0:let rem=left%right;left=right;right=rem
    return left
fn p180_sqrt(value:Int64)->Int64:
    if value<=0:return 0
    var root=value;var next=(root+value//root)//2
    while next<root:root=next;next=(root+value//root)//2
    return root
fn p180_insert(inout nums:InlineArray[Int64,524288],inout dens:InlineArray[Int64,524288],numerator:Int64,denominator:Int64):Bool:
    var index=Int(((numerator%524288)*1009+denominator%524288)&524287)
    while dens[index]!=0:
        if nums[index]==numerator and dens[index]==denominator:return False
        index=(index+1)&524287
    nums[index]=numerator;dens[index]=denominator
    return True
fn p180_record(inout nums:InlineArray[Int64,524288],inout dens:InlineArray[Int64,524288],xn:Int64,xd:Int64,yn:Int64,yd:Int64,zn_in:Int64,zd_in:Int64,order:Int64):
    if zn_in<=0 or zd_in<=0:return
    var zn=zn_in;var zd=zd_in;var g=p180_gcd(zn,zd);zn//=g;zd//=g
    if zn>=zd or zd>order:return
    let numerator=xn*yd*zd+yn*xd*zd+zn*xd*yd;let denominator=xd*yd*zd
    g=p180_gcd(numerator,denominator)
    _=p180_insert(nums,dens,numerator//g,denominator//g)
fn p180_add_big(inout limbs:InlineArray[Int64,8],value_in:Int64):
    var value=value_in;var index=0
    while value>0:
        let total=limbs[index]+value;limbs[index]=total%10000;value//=10000;index+=1
@export("problem180")
fn problem180(order:Int64) abi("C")->Int64:
    if order<1 or order>35:return -1
    var nums=InlineArray[Int64,524288](fill=0);var dens=InlineArray[Int64,524288](fill=0)
    for xn in range(1,Int(order+1)):
        for xd in range(xn+1,Int(order+1)):
            if p180_gcd(Int64(xn),Int64(xd))!=1:continue
            for yn in range(1,Int(order+1)):
                for yd in range(yn+1,Int(order+1)):
                    if p180_gcd(Int64(yn),Int64(yd))!=1 or xn*yd>yn*xd:continue
                    var zn=Int64(xn*yd+xd*yn);var zd=Int64(xd*yd)
                    p180_record(nums,dens,Int64(xn),Int64(xd),Int64(yn),Int64(yd),zn,zd,order)
                    var sn=Int64(xn*xn*yd*yd+xd*xd*yn*yn);var sd=Int64(xd*xd*yd*yd)
                    var rn=p180_sqrt(sn);var rd=p180_sqrt(sd)
                    if rn*rn==sn and rd*rd==sd:p180_record(nums,dens,Int64(xn),Int64(xd),Int64(yn),Int64(yd),rn,rd,order)
                    zn=Int64(xn*yn);zd=Int64(xd*yn+xn*yd)
                    p180_record(nums,dens,Int64(xn),Int64(xd),Int64(yn),Int64(yd),zn,zd,order)
                    sn=Int64(xn*xn*yn*yn);sd=Int64(xd*xd*yn*yn+xn*xn*yd*yd)
                    rn=p180_sqrt(sn);rd=p180_sqrt(sd)
                    if rn*rn==sn and rd*rd==sd:p180_record(nums,dens,Int64(xn),Int64(xd),Int64(yn),Int64(yd),rn,rd,order)
    var common=Int64(1)
    for factor in range(2,Int(order+1)):
        common=common//p180_gcd(common,Int64(factor))*Int64(factor)
    var total=InlineArray[Int64,8](fill=0)
    for idx in range(524288):
        if dens[idx]!=0:
            if common%dens[idx]!=0:return -1
            p180_add_big(total,nums[idx]*(common//dens[idx]))
    var remainder=Int64(0)
    for idx in range(7,-1,-1):remainder=(remainder*10000+total[idx])%common
    let divisor=p180_gcd(remainder,common);remainder=0
    for idx in range(7,-1,-1):
        let current=remainder*10000+total[idx];total[idx]=current//divisor;remainder=current%divisor
    var numerator=Int64(0)
    for idx in range(7,-1,-1):
        if numerator>(9223372036854775807-total[idx])//10000:return -1
        numerator=numerator*10000+total[idx]
    let denominator=common//divisor
    if numerator>9223372036854775807-denominator:return -1
    return numerator+denominator
