@export("problem17")
fn problem17(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>1000:return -1
    var ones=InlineArray[Int64,20](fill=0);var tens=InlineArray[Int64,10](fill=0)
    ones[0]=0;ones[1]=3;ones[2]=3;ones[3]=5;ones[4]=4;ones[5]=4;ones[6]=3;ones[7]=5;ones[8]=5;ones[9]=4
    ones[10]=3;ones[11]=6;ones[12]=6;ones[13]=8;ones[14]=8;ones[15]=7;ones[16]=7;ones[17]=9;ones[18]=8;ones[19]=8
    tens[0]=0;tens[1]=0;tens[2]=6;tens[3]=6;tens[4]=5;tens[5]=5;tens[6]=5;tens[7]=7;tens[8]=6;tens[9]=6
    var total=Int64(0)
    for val in range(1,Int(limit+1)):
        if val==1000:total+=ones[1]+8;continue
        var rem=val
        if val>=100:
            total+=ones[val//100]+7;rem=val%100
            if rem!=0:total+=3
        if rem<20:total+=ones[rem]
        else:total+=tens[rem//10]+ones[rem%10]
    return total
