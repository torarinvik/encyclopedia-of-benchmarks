"""Oracle for the pinned triangular FuzzySet methods."""
import struct
MAX_INPUT_LENGTH=8
MAX_OUTPUT_BYTES=24

def expected_output(v):
    if not isinstance(v,(list,tuple)) or len(v)!=8 or any(type(x) is not int or not -(2**63)<=x<2**63 for x in v):return -1,b""
    op,*z=v
    if not 0<=op<=3 or any(not 0<=x<=1000 for x in z):return -1,b""
    a=z[:3];b=z[3:6];x=z[6]/1000
    if op==0:
        if any(b) or z[6]!=0:return -1,b""
        out=[1-a[2],1-a[0],1-a[1]]
    elif op==1:
        if z[6]!=0:return -1,b""
        out=[max(a[0],b[0]),min(a[2],b[2]),(a[1]+b[1])/2]
    elif op==2:
        if z[6]!=0:return -1,b""
        out=[min(a[0],b[0]),(a[1]+b[1])/2,max(a[2],b[2])]
    else:
        if any(b) or not a[0]<a[1]<a[2]:return -1,b""
        left,peak,right=[q/1000 for q in a]
        if x<=left or x>=right: y=0.0
        elif left<x<=peak:y=(x-left)/(peak-left)
        elif peak<x<right:y=(right-x)/(right-peak)
        else:return -1,b""
        out=[y]
    return 8*len(out),struct.pack('<'+'d'*len(out),*out)
