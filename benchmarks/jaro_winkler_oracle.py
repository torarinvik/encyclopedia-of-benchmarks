"""Reference for the bounded Python Jaro-Winkler behavior."""
INVALID_RESULT=-1.0e300
MAX_INPUT_LENGTH=66
def expected_result(values):
    if not isinstance(values,(list,tuple)) or len(values)<2 or len(values)>MAX_INPUT_LENGTH:return INVALID_RESULT
    if any(type(v)is not int or not -(1<<63)<=v<(1<<63) for v in values):return INVALID_RESULT
    n1=values[0]
    if not 0<=n1<=32 or 1+n1>=len(values):return INVALID_RESULT
    p2=1+n1;n2=values[p2]
    if not 0<=n2<=32 or len(values)!=p2+1+n2:return INVALID_RESULT
    a=values[1:p2];b=values[p2+1:]
    if any(x<0 or x>127 for x in a+b):return INVALID_RESULT
    def matched(x,y):
        used=[False]*len(y);out=[];radius=min(len(x),len(y))//2
        for i,ch in enumerate(x):
            lo=max(0,i-radius);hi=min(i+radius+1,len(y))
            for j in range(lo,hi):
                if not used[j] and y[j]==ch:
                    used[j]=True;out.append(ch);break
        return out
    ma=matched(a,b);mb=matched(b,a);m=len(ma)
    t=sum(x!=y for x,y in zip(ma,mb))//2
    if not m:jaro=0.0
    else:jaro=(m/len(a)+m/len(b)+(m-t)/m)/3.0
    prefix=0
    for x,y in zip(a[:4],b[:4]):
        if x!=y:break
        prefix+=1
    return jaro+0.1*prefix*(1.0-jaro)
