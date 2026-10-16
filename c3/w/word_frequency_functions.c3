module word_frequency_functions;
extern fn double log10(double x);
extern fn double floor(double x);
const usz MAX_TERM=128, MAX_TEXT=4096, MAX_PACKED=4227;
const long MAX_COUNT=1000000;
fn bool punct(uchar c){return(c>=33&&c<=47)||(c>=58&&c<=64)||(c>=91&&c<=96)||(c>=123&&c<=126);}
fn uchar lower_ascii(uchar c){return c>=65&&c<=90?(uchar)(c+32):c;}
fn void put32(uchar*o,usz*p,uint x){uint b=x;for(usz i=0;i<4;i++){o[*p]=(uchar)(b&255);*p+=1;b>>=8;}}
fn void put64(uchar*o,usz*p,long x){ulong b=(ulong)x;for(usz i=0;i<8;i++){o[*p]=(uchar)(b&255);*p+=1;b>>=8;}}
fn long milli(double x){double y=x*1000.0,lo=floor(y),f=y-lo;if(f<0.5)return (long)lo;if(f>0.5)return (long)(lo+1.0);long k=(long)lo;return k%2==0?k:k+1;}
fn long word_frequency_functions(long*in,usz length,uchar*out,usz capacity) @export("word_frequency_functions"){
 if(in==null||length<1||length>MAX_PACKED)return -1;long op=in[0],kind=0,a=0,b=0;usz outlen=12;
 if(op==0||op==1){
  if(length<3||in[1]<0||in[1]>128)return -1;usz tn=(usz)in[1],ti=2+tn;
  if(length<ti+1||in[ti]<0||in[ti]>4096)return -1;usz dn=(usz)in[ti],di=ti+1;if(length!=di+dn)return -1;
  uchar[128] term;uchar[4096] text,clean;
  for(usz i=0;i<tn;i++){if(in[2+i]<0||in[2+i]>127)return -1;term[i]=lower_ascii((uchar)in[2+i]);}
  for(usz i=0;i<dn;i++){if(in[di+i]<0||in[di+i]>127)return -1;text[i]=(uchar)in[di+i];}
  usz cn=0;for(usz i=0;i<dn;i++)if(!punct(text[i])&&(op!=0||text[i]!=10)){clean[cn]=op==1?lower_ascii(text[i]):text[i];cn++;}
  if(op==0){usz start=0;for(usz i=0;i<=cn;i++)if(i==cn||clean[i]==32){usz n=i-start;bool same=n==tn;for(usz j=0;same&&j<n;j++)if(lower_ascii(clean[start+j])!=term[j])same=false;if(same)a++;start=i+1;}kind=0;}
  else{kind=1;outlen=20;usz start=0;for(usz i=0;i<=cn;i++)if(i==cn||clean[i]==10){usz n=i-start;bool found=tn==0;for(usz j=0;!found&&j+tn<=n;j++){usz k=0;while(k<tn&&clean[start+j+k]==term[k])k++;if(k==tn)found=true;}if(found)a++;b++;start=i+1;}}
 }else if(op==2){
  if(length!=4)return -1;long df=in[1],n=in[2],smooth=in[3];if(df<0||df>MAX_COUNT||n<0||n>MAX_COUNT||(smooth!=0&&smooth!=1))return -1;
  if(smooth&&n==0){kind=4;outlen=4;}else if(!smooth&&df==0){kind=3;outlen=4;}else if(!smooth&&n==0){kind=4;outlen=4;}else{double v=smooth?1.0+log10((double)n/(double)(1+df)):log10((double)n/(double)df);kind=2;a=milli(v);}
 }else if(op==3){if(length!=3||in[1]<0||in[1]>MAX_COUNT||in[2]<-MAX_COUNT||in[2]>MAX_COUNT)return -1;kind=2;a=in[1]*in[2];}
 else return -1;
 if(out==null||capacity<outlen)return -2;usz p=0;put32(out,&p,(uint)kind);if(kind==0||kind==2)put64(out,&p,a);else if(kind==1){put64(out,&p,a);put64(out,&p,b);}return (long)p;
}
