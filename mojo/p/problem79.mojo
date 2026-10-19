fn p79_next(inout d:InlineArray[Int32,10],n:Int)->Bool:
    var pivot=n-2
    while pivot>=0 and d[pivot]>=d[pivot+1]:pivot-=1
    if pivot<0:return False
    var successor=n-1
    while d[successor]<=d[pivot]:successor-=1
    let t=d[pivot];d[pivot]=d[successor];d[successor]=t
    var l=pivot+1;var r=n-1
    while l<r:let x=d[l];d[l]=d[r];d[r]=x;l+=1;r-=1
    return True
@export("problem79")
fn problem79(placeholder:Int64) abi("C")->Int64:
    if placeholder!=0:return -1
    var attempts=InlineArray[Int32,50](fill=0)
    attempts[0]=319;attempts[1]=680;attempts[2]=180;attempts[3]=690;attempts[4]=129;attempts[5]=620;attempts[6]=762;attempts[7]=689;attempts[8]=762;attempts[9]=318
    attempts[10]=368;attempts[11]=710;attempts[12]=720;attempts[13]=710;attempts[14]=629;attempts[15]=168;attempts[16]=160;attempts[17]=689;attempts[18]=716;attempts[19]=731
    attempts[20]=736;attempts[21]=729;attempts[22]=316;attempts[23]=729;attempts[24]=729;attempts[25]=710;attempts[26]=769;attempts[27]=290;attempts[28]=719;attempts[29]=680
    attempts[30]=318;attempts[31]=389;attempts[32]=162;attempts[33]=289;attempts[34]=162;attempts[35]=718;attempts[36]=729;attempts[37]=319;attempts[38]=790;attempts[39]=680
    attempts[40]=890;attempts[41]=362;attempts[42]=319;attempts[43]=760;attempts[44]=316;attempts[45]=729;attempts[46]=380;attempts[47]=319;attempts[48]=728;attempts[49]=716
    var present=InlineArray[Bool,10](fill=False)
    for i in range(50):
        let v=attempts[i];present[v//100]=True;present[(v//10)%10]=True;present[v%10]=True
    var digits=InlineArray[Int32,10](fill=0);var n=0
    for d in range(10):if present[d]:digits[n]=Int32(d);n+=1
    while True:
        var pos=InlineArray[Int32,10](fill=-1)
        for i in range(n):pos[digits[i]]=Int32(i)
        var good=True
        for i in range(50):
            let v=attempts[i];let a=v//100;let b=(v//10)%10;let c=v%10
            if !(pos[a]<pos[b] and pos[b]<pos[c]):good=False;break
        if good:
            var result=Int64(0)
            for i in range(n):result=result*10+Int64(digits[i])
            return result
        if !p79_next(digits,n):break
    return -1
