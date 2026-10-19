from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn p54_rank(cards:InlineArray[Int64,5])->InlineArray[Int64,6]:
    var ranks=InlineArray[Int64,5](fill=0);var suits=InlineArray[Int64,5](fill=0);var counts=InlineArray[Int32,15](fill=0)
    for i in range(5):ranks[i]=cards[i]//4+2;suits[i]=cards[i]%4;counts[Int(ranks[i])]+=1
    for i in range(1,5):
        let value=ranks[i];var j=i
        while j>0 and ranks[j-1]<value:ranks[j]=ranks[j-1];j-=1
        ranks[j]=value
    var score=InlineArray[Int64,6](fill=0);var flush=True
    for i in range(1,5):if suits[i]!=suits[0]:flush=False
    var distinct=True
    for r in range(2,15):if counts[r]>1:distinct=False
    var sh=Int64(0)
    if distinct and ranks[0]-ranks[4]==4:sh=ranks[0]
    elif distinct and ranks[0]==14 and ranks[1]==5 and ranks[2]==4 and ranks[3]==3 and ranks[4]==2:sh=5
    var four=Int64(0);var three=Int64(0);var ph=Int64(0);var pl=Int64(0);var singles=InlineArray[Int64,5](fill=0);var sc=0
    for r in range(14,1,-1):
        if counts[r]==4:four=Int64(r)
        elif counts[r]==3:three=Int64(r)
        elif counts[r]==2:
            if ph==0:ph=Int64(r)
            else:pl=Int64(r)
        elif counts[r]==1:singles[sc]=Int64(r);sc+=1
    if flush and sh!=0:score[0]=9 if sh==14 else 8;score[1]=sh
    elif four!=0:score[0]=7;score[1]=four;score[2]=singles[0]
    elif three!=0 and ph!=0:score[0]=6;score[1]=three;score[2]=ph
    elif flush:
        score[0]=5
        for i in range(5):score[i+1]=ranks[i]
    elif sh!=0:score[0]=4;score[1]=sh
    elif three!=0:score[0]=3;score[1]=three;score[2]=singles[0];score[3]=singles[1]
    elif pl!=0:score[0]=2;score[1]=ph;score[2]=pl;score[3]=singles[0]
    elif ph!=0:score[0]=1;score[1]=ph;score[2]=singles[0];score[3]=singles[1];score[4]=singles[2]
    else:
        for i in range(5):score[i+1]=ranks[i]
    return score
@export("problem54")
fn problem54(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=10000:return -1
    var wins=Int64(0)
    for deal in range(1000):
        let offset=deal*10;var cards=InlineArray[Int64,5](fill=0);var first=InlineArray[Int64,5](fill=0);var second=InlineArray[Int64,5](fill=0)
        for i in range(10):
            let card=input[offset+i]
            if card<0 or card>=52:return -1
            for j in range(i):if input[offset+j]==card:return -1
            if i<5:first[i]=card
            else:second[i-5]=card
        let a=p54_rank(first);let b=p54_rank(second);var cmp=0
        for i in range(6):if a[i]!=b[i]:cmp=1 if a[i]>b[i] else -1;break
        if cmp>0:wins+=1
    return wins
