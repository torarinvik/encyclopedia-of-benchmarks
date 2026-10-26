module two_dimensional_string_matching;
const usz D=8;const usz MAX_INPUT=132;
fn void put64(char*o,usz p,long x){ulong b=(ulong)x;for(usz j=0;j<8;j+=1){o[p+j]=(char)(b&255);b>>=8;}}
long two_dimensional_string_matching(long*in,usz len,char*out,usz cap) @export("two_dimensional_string_matching"){
 if(in==null||len<6||len>MAX_INPUT)return -1;long rr=in[0],cc=in[1],hr=in[2],wc=in[3];if(rr<1||rr>8||cc<1||cc>8||hr<1||hr>rr||wc<1||wc>cc)return -1;usz r=(usz)rr,c=(usz)cc,h=(usz)hr,w=(usz)wc;if(len!=4+r*c+h*w)return -1;long text[64],pat[64];usz p=4;for(usz i=0;i<r*c;i+=1){text[i]=in[p++];if(text[i]<0||text[i]>3)return -1;}for(usz i=0;i<h*w;i+=1){pat[i]=in[p++];if(pat[i]<0||pat[i]>3)return -1;}
 long prefix[8]={0};for(usz i=1;i<h;i+=1){usz q=(usz)prefix[i-1];while(q>0){bool eq=true;for(usz j=0;j<w;j+=1)if(pat[i*w+j]!=pat[q*w+j])eq=false;if(eq)break;q=(usz)prefix[q-1];}bool eq=true;for(usz j=0;j<w;j+=1)if(pat[i*w+j]!=pat[q*w+j])eq=false;if(eq)q+=1;prefix[i]=(long)q;}
 bool mark[512]={false};for(usz tr=0;tr<r;tr+=1)for(usz col=0;col<=c-w;col+=1)for(usz pr=0;pr<h;pr+=1){bool eq=true;for(usz j=0;j<w;j+=1)if(text[tr*c+col+j]!=pat[pr*w+j])eq=false;mark[(tr*8+col)*8+pr]=eq;}
 long mr[64],mc[64];usz count=0;for(usz col=0;col<=c-w;col+=1){usz q=0;for(usz tr=0;tr<r;tr+=1){while(q>0&&!mark[(tr*8+col)*8+q])q=(usz)prefix[q-1];if(mark[(tr*8+col)*8+q])q+=1;if(q==h){mr[count]=(long)(tr+1-h);mc[count]=(long)col;count+=1;q=(usz)prefix[h-1];}}}usz bytes=8*(1+2*count);if(out==null||cap<bytes)return -2;put64(out,0,(long)count);for(usz i=0;i<count;i+=1){put64(out,8*(1+2*i),mr[i]);put64(out,8*(2+2*i),mc[i]);}return (long)bytes;
}
