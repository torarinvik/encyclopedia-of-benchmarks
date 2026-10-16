"""Reference for the source-compatible bounded Jaro similarity contract."""
from __future__ import annotations
import math

INVALID_RESULT=-1.0e300
MAX_INPUT_LENGTH=66

def expected_result(values:list[int])->float:
    if not isinstance(values,list) or len(values)<2 or len(values)>MAX_INPUT_LENGTH or any(type(v)is not int or not -(2**63)<=v<2**63 for v in values):return INVALID_RESULT
    n1=values[0]
    if not 0<=n1<=32 or 1+n1>=len(values):return INVALID_RESULT
    p2=1+n1;n2=values[p2]
    if not 0<=n2<=32 or n1<n2 or len(values)!=p2+1+n2:return INVALID_RESULT
    s1=values[1:p2];s2=values[p2+1:]
    if any(c<0 or c>127 for c in s1+s2):return INVALID_RESULT
    if s1==s2:return 1.0
    radius=max(max(n1,n2)//2-1,0)
    m1=[False]*n1;m2=[False]*n2;matches=0
    for i in range(n1):
        start=max(i-radius,0);end=min(i+radius,n2-1)
        for j in range(start,end+1):
            if s1[i]==s2[j] and not m2[j]:
                matches+=1;m1[i]=True;m2[j]=True;break
    if matches==0:return 0.0
    transpositions=0;j=0
    for i in range(n1):
        if m1[i]:
            while not m2[j]:j+=1
            if s1[i]!=s2[j]:transpositions+=1
            j+=1
    transpositions//=2
    return ((matches/n1)+(matches/n2)+((matches-transpositions)/matches))/3.0
