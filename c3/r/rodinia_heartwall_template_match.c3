module rodinia_heartwall_template_match;
import "math";
const long MAX_INPUT = 85;
fn long rodinia_heartwall_template_match(long* v, usz n, char* output, usz capacity) @export("rodinia_heartwall_template_match") {
    if (v == null || n < 5 || n > MAX_INPUT) return -1;
    long irv=v[0], icv=v[1], trv=v[2], tcv=v[3], maskv=v[4];
    if(irv<2||irv>8||icv<2||icv>8||trv<2||trv>4||tcv<2||tcv>4||trv>irv||tcv>icv||maskv<0)return -1;
    usz ir=(usz)irv,ic=(usz)icv,tr=(usz)trv,tc=(usz)tcv,nr=ir-tr+1,nc=ic-tc+1,count=nr*nc;
    if(((ulong)maskv>>count)!=0||n!=5+tr*tc+ir*ic)return -1;
    for(usz i=5;i<n;i++)if(v[i]<0||v[i]>255)return -1;
    usz nn=tr*tc,ibase=5+nn;float tsum=0,tsq=0;
    for(usz c=0;c<tc;c++)for(usz r=0;r<tr;r++){float x=(float)v[5+c*tr+r];tsum+=x;tsq+=x*x;}
    float nf=(float)nn,tm=tsum/nf,tv=tsq/nf-tm*tm;if(!(tv>0))return -1;
    float best=0;usz besti=0,k=0;
    for(usz c0=0;c0<nc;c0++)for(usz r0=0;r0<nr;r0++,k++)if((((ulong)maskv>>k)&1)!=0){float ps=0,pq=0,dot=0;
        for(usz c=0;c<tc;c++)for(usz r=0;r<tr;r++){float x=(float)v[5+c*tr+r],y=(float)v[ibase+(c0+c)*ir+r0+r];ps+=y;pq+=y*y;dot+=x*y;}
        float centered=pq-ps*ps/nf;if(centered<0)centered=0;if(!(centered>0))return -1;
        float num=dot-ps*tsum/nf;float denomT=math.sqrt((float)(nn-1))*math.sqrt(tv);float den=math.sqrt(centered)*denomT;float mag=math.abs(num/den);
        if(math.is_nan(mag)||math.is_inf(mag))return -1;if(mag>best){best=mag;besti=k;}
    }
    if(output==null||capacity<8)return -2;ulong bits=(ulong)besti;for(usz b=0;b<8;b++)output[b]=(char)((bits>>(8*b))&255);return 8;
}
