"""Oracle for bounded Zadeh fuzzy set operations."""
import struct
MAX_INPUT_LENGTH=29
MAX_OUTPUT_BYTES=64

def expected_output(v):
    if not isinstance(v,(list,tuple)) or any(type(x) is not int or not -(2**63)<=x<2**63 for x in v):return -1,b""
    if len(v)<8:return -1,b""
    op,n,left,peak,right=v[:5]
    if not 0<=op<=8 or not 1<=n<=8 or len(v)!=5+3*n:return -1,b""
    grid=v[5:5+n];a=v[5+n:5+2*n];b=v[5+2*n:]
    if any(not 0<=x<=1000 for x in grid+a+b):return -1,b""
    if op==0:
        if not 0<=left<=peak<=right<=1000 or any(a+b):return -1,b""
        l,p,r=(left/1000,peak/1000,right/1000);out=[]
        for raw in grid:
            x=raw/1000
            ls=(x-l)/(p-l) if p>l else (0 if x<p else 1)
            rs=(r-x)/(r-p) if r>p else (0 if x>p else 1)
            out.append(min(1.0,max(0.0,min(ls,rs))) )
    else:
        if left or peak or right or any(grid):return -1,b""
        aa=[x/1000 for x in a];bb=[x/1000 for x in b];out=[]
        for x,y in zip(aa,bb):
            if op==1:z=max(x,y)
            elif op==2:z=min(x,y)
            elif op==3:z=1.0-x
            elif op==4:z=min(x,1.0-y)
            elif op==5:z=x+y-x*y
            elif op==6:z=x*y
            elif op==7:z=min(1.0,x+y)
            else:z=max(0.0,x+y-1.0)
            out.append(z)
    return 8*n,struct.pack('<'+'d'*n,*out)
