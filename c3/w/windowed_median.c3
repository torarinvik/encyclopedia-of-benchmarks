module windowed_median;
const usz MAX_WINDOW=64,MAX_STREAM=128;
fn void put_f64(double value,char* output,usz offset){ulong bits=@bitcast(ulong,value);for(usz b=0;b<8;b++){output[offset+b]=(char)(bits&255);bits>>=8;}}
fn long windowed_median(long* input,usz length,char* output,usz capacity) @export("windowed_median"){
 if(input==null||length<3)return -1;long wv=input[0],nv=input[1];if(wv<1||wv>MAX_WINDOW||nv<1||nv>MAX_STREAM)return -1;usz w=(usz)wv,n=(usz)nv;if(length!=n+2)return -1;
 for(usz i=0;i<n;i++)if(input[2+i]<-1000000||input[2+i]>1000000)return -1;if(capacity<n*8||output==null)return -2;
 long[MAX_WINDOW] sorted;usz active=0;
 for(usz i=0;i<n;i++){if(i>=w){long old=input[2+i-w];usz p=0;while(p<active&&sorted[p]!=old)p++;if(p==active)return -1;for(usz j=p+1;j<active;j++)sorted[j-1]=sorted[j];active--;}
 long value=input[2+i];usz p=0;while(p<active&&sorted[p]<value)p++;usz j=active;while(j>p){sorted[j]=sorted[j-1];j--;}sorted[p]=value;active++;
 float median;if((active&1)==1)median=(float)sorted[active/2];else median=0.5f*(float)sorted[active/2-1]+0.5f*(float)sorted[active/2];put_f64((double)median,output,i*8);}
 return (long)(n*8);
}
