from collections.abc import Sequence
MAX_INPUT_LENGTH=22
MAX_VALID_INPUT_LENGTH=20
INVALID_RESULT=-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)<2 or len(values)>20 or len(values)%2:return -1
    if any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1
    dq=[];events=[]
    for i in range(0,len(values),2):
        op,arg=values[i:i+2]
        if not 0<=op<=6:return -1
        if op in (0,1):
            if not -15<=arg<=15:return -1
            if op==0:dq.insert(0,arg)
            else:dq.append(arg)
        elif arg!=0:return -1
        elif op==2:events.append(dq.pop(0)+16 if dq else 0)
        elif op==3:events.append(dq.pop()+16 if dq else 0)
        elif op==4:events.append(dq[0]+16 if dq else 0)
        elif op==5:events.append(dq[-1]+16 if dq else 0)
        else:events.append(1 if not dq else 2)
    out=0;place=1
    for digit in events:out+=digit*place;place*=32
    return out
