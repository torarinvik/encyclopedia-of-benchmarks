"""Independent bounded fixed-point oracle for EDN's separable JPEG DCT."""
from collections.abc import Sequence

def _i16(x:int)->int:
    x &= 0xffff
    return x-65536 if x>=32768 else x

def _line(d:list[int],base:int,k:int,m:int,n:int,r:Sequence[int])->None:
    t=[0]*12
    for j in range(4):
        a=d[base+k*j];b=d[base+k*(7-j)]
        t[j]=a+b;t[7-j]=a-b
    t[8]=t[0]+t[3];t[9]=t[0]-t[3];t[10]=t[1]+t[2];t[11]=t[1]-t[2]
    d[base]=_i16((t[8]+t[10])>>m)
    d[base+4*k]=_i16((t[8]-t[10])>>m)
    t[8]=_i16(t[11]+t[9])*r[10]
    d[base+2*k]=_i16(t[8+0]+_i16((t[9]*r[9])>>n))
    d[base+6*k]=_i16(t[8]+_i16((t[11]*r[11])>>n))
    t[0]=_i16(t[4]+t[7])*r[2];t[1]=_i16(t[5]+t[6])*r[0]
    t[2]=t[4]+t[6];t[3]=t[5]+t[7]
    t[8]=_i16(t[2]+t[3])*r[8]
    t[2]=_i16(t[2])*r[1]+t[8];t[3]=_i16(t[3])*r[3]+t[8]
    d[base+7*k]=_i16(t[4]*r[4]+t[0]+t[2])>>n
    d[base+5*k]=_i16(t[5]*r[6]+t[1]+t[3])>>n
    d[base+3*k]=_i16(t[6]*r[5]+t[1]+t[2])>>n
    d[base+1*k]=_i16(t[7]*r[7]+t[0]+t[3])>>n

def oracle(values:Sequence[int],capacity:int|None=None)->tuple[int,bytes]:
    if len(values)!=76 or any(type(x) is not int for x in values):return -1,b""
    d=list(values[:64]);r=values[64:]
    if any(not -8<=x<=8 for x in d) or any(not -32<=x<=31 for x in r):return -1,b""
    for row in range(8):_line(d,row*8,1,0,13,r)
    for col in range(8):_line(d,col,8,3,16,r)
    out=b"".join(x.to_bytes(8,"little",signed=True) for x in d)
    if capacity is not None and capacity<len(out):return -2,b""
    return len(out),out
