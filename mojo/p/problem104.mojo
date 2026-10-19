from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn p104_pan(x:UInt32)->Bool:
    var mask=UInt16(0)
    for _ in range(9):
        let d=x%10
        if d==0 or (mask&(UInt16(1)<<d))!=0:return False
        mask|=UInt16(1)<<d;x//=10
    return x==0 and mask==0x3fe
@export("problem104")
fn problem104(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]!=0:return -1
    var a=InlineArray[UInt32,24000](fill=0);var b=InlineArray[UInt32,24000](fill=0);a[0]=1;b[0]=1
    var lena=1;var lenb=1;var active=True
    for index in range(3,1000003):
        var sumlen=if lena>lenb:lena else:lenb;var carry=UInt64(0);var nextlen=sumlen
        if active:
            for i in range(sumlen):
                let left=UInt64(a[i]);let right=UInt64(b[i]);let s=left+right+carry
                a[i]=UInt32(s%1000000000);carry=s//1000000000
            if carry>0:
                if nextlen>=24000:return -1
                a[nextlen]=UInt32(carry);nextlen+=1
            lena=lenb;lenb=nextlen;active=False
            if p104_pan(a[0]):
                let top=a[lenb-1];var width=0;var z=top
                while z>0:width+=1;z//=10
                var leading=top
                if width<9 and lenb>1:
                    var p=UInt32(1)
                    for _ in range(width):p*=10
                    var fill=UInt32(1)
                    for _ in range(9-width):fill*=10
                    leading=top*fill+a[lenb-2]/p
                if p104_pan(leading):return Int64(index)
        else:
            for i in range(sumlen):
                let left=UInt64(b[i]);let right=UInt64(a[i]);let s=left+right+carry
                b[i]=UInt32(s%1000000000);carry=s//1000000000
            if carry>0:
                if nextlen>=24000:return -1
                b[nextlen]=UInt32(carry);nextlen+=1
            lenb=nextlen;active=True
            if p104_pan(b[0]):
                let top=b[lena-1];var width=0;var z=top
                while z>0:width+=1;z//=10
                var leading=top
                if width<9 and lena>1:
                    var p=UInt32(1)
                    for _ in range(width):p*=10
                    var fill=UInt32(1)
                    for _ in range(9-width):fill*=10
                    leading=top*fill+b[lena-2]/p
                if p104_pan(leading):return Int64(index)
    return -1
