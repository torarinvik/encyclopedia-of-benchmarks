module lz77_infinite_rightmost;
const MAX_TEXT = 64, MAX_INPUT = 66, MAX_OUTPUT = 1536;
fn void put64(char* o, usz at, long v){ulong b=(ulong)v;for(usz i=0;i<8;i++){o[at+i]=(char)(b&255);b>>=8;}}
long lz77_infinite_rightmost(long* in,usz len,char* out,usz cap) @export("lz77_infinite_rightmost") {
    if(in==null||len<1||len>MAX_INPUT||in[0]<0||in[0]>MAX_TEXT)return -1;
    usz n=(usz)in[0];if(len!=n+1)return -1;
    for(usz i=0;i<n;i++)if(in[i+1]<32||in[i+1]>126)return -1;
    char[MAX_OUTPUT] staged=zeroed;usz tokens=0,q=0;
    while(q<n){usz bl=0,bp=0;bool found=false;
        for(usz p=0;p<q;p++){usz l=0;while(q+l<n&&in[p+l+1]==in[q+l+1])l++;
            if(l>bl||(l==bl&&l>0&&(!found||p>bp))){bl=l;bp=p;found=true;}}
        long source_pos=found?(long)bp:0;usz np=q+bl;long ch=np<n?in[np+1]:0;usz at=tokens*24;
        put64(&staged[0],at,source_pos);put64(&staged[0],at+8,(long)bl);put64(&staged[0],at+16,ch);tokens++;
        q=ch!=0?np+1:np;
    }
    usz bytes=tokens*24;if(out==null||cap<bytes)return -2;
    for(usz i=0;i<bytes;i++)out[i]=(uint8)staged[i];return (long)bytes;
}
