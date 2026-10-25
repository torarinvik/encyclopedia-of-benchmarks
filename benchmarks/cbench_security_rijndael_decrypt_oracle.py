"""Independent byte-oriented oracle for the cBench AES-256 decrypt block."""
from collections.abc import Sequence
KEY_BYTES=32
BLOCK_BYTES=16
INPUT_BYTES=48
OUTPUT_BYTES=16
INVALID_RESULT=-1
OUTPUT_ERROR=-2

def _mul(a,b):
    r=0
    while b:
        if b&1:r^=a
        a=((a<<1)^(0x11b if a&0x80 else 0))&255
        b>>=1
    return r

def _pow(a,n):
    r=1
    while n:
        if n&1:r=_mul(r,a)
        a=_mul(a,a);n>>=1
    return r

def _boxes():
    forward=[]
    for x in range(256):
        q=_pow(x,254) if x else 0
        forward.append((q ^ (((q<<1)|(q>>7))&255) ^ (((q<<2)|(q>>6))&255) ^ (((q<<3)|(q>>5))&255) ^ (((q<<4)|(q>>4))&255) ^ 0x63)&255)
    inverse=[0]*256
    for x,y in enumerate(forward):inverse[y]=x
    return forward,inverse

def _decrypt(key,block):
    sbox,inv=_boxes();rc=(1,2,4,8,16,32,64)
    rk=list(key)
    while len(rk)<240:
        wi=len(rk)//4;t=rk[-4:].copy()
        if wi%8==0:
            t=t[1:]+t[:1];t=[sbox[x] for x in t];t[0]^=rc[wi//8-1]
        elif wi%8==4:t=[sbox[x] for x in t]
        for j in range(4):rk.append(rk[-32]^t[j])
    st=[block[i]^rk[224+i] for i in range(16)]
    def inv_shift_sub():
        prev=st.copy()
        for col in range(4):
            for row in range(4):st[row+4*col]=inv[prev[row+4*((col+4-row)%4)]]
    for rnd in range(13,0,-1):
        inv_shift_sub()
        for i in range(16):st[i]^=rk[rnd*16+i]
        for col in range(4):
            o=4*col;a,b,c,d=st[o:o+4]
            st[o:o+4]=[_mul(a,14)^_mul(b,11)^_mul(c,13)^_mul(d,9),_mul(a,9)^_mul(b,14)^_mul(c,11)^_mul(d,13),_mul(a,13)^_mul(b,9)^_mul(c,14)^_mul(d,11),_mul(a,11)^_mul(b,13)^_mul(c,9)^_mul(d,14)]
    inv_shift_sub()
    for i in range(16):st[i]^=rk[i]
    return bytes(st)

def expected_output(values):
    if not isinstance(values,Sequence) or len(values)!=INPUT_BYTES:return None
    if any(not isinstance(x,int) or x<0 or x>255 for x in values):return None
    return _decrypt(values[:KEY_BYTES],values[KEY_BYTES:])

def expected_result(values,output_capacity=OUTPUT_BYTES,output_is_null=False):
    if expected_output(values) is None:return INVALID_RESULT
    if output_is_null or output_capacity<OUTPUT_BYTES:return OUTPUT_ERROR
    return OUTPUT_BYTES
