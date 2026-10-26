// Clean-room generalized vector First Fit bin-packing profile.
module vector_bin_packing;
const N:usz=32,D:usz=4,MAX_INPUT:usz=130,FIELDS:usz=161;
fn void put(char* out,usz at,long x){ulong b=(ulong)x;for(usz i=0;i<8;++i){out[at+i]=(char)(b&255ul);b>>=8;}}
fn long vector_bin_packing(long* input,usz length,char* output,usz capacity) @export("vector_bin_packing"){
 if(input==null||length<2||length>MAX_INPUT)return -1;long n64=input[0],d64=input[1];if(n64<1||n64>32||d64<1||d64>4||length!=2+(usz)(n64*d64))return -1;usz n=(usz)n64,d=(usz)d64;for(usz i=0;i<n*d;++i){long x=input[2+i];if(x<0||x>1000)return -1;}
 long[N*D] loads={};usz[N] assignment={};usz bins=0;for(usz item=0;item<n;++item){usz chosen=bins;for(usz b=0;b<bins;++b){bool fits=true;for(usz q=0;q<d;++q){if(loads[b*D+q]+input[2+item*d+q]>1000)fits=false;}if(fits){chosen=b;break;}}if(chosen==bins)++bins;assignment[item]=chosen;for(usz q=0;q<d;++q)loads[chosen*D+q]+=input[2+item*d+q];}
 long[FIELDS] staged={};usz count=0;staged[count++]=(long)bins;for(usz i=0;i<n;++i)staged[count++]=(long)assignment[i];for(usz b=0;b<bins;++b){for(usz q=0;q<d;++q)staged[count++]=loads[b*D+q];}if(output==null||capacity<8*count)return -2;for(usz i=0;i<count;++i)put(output,8*i,staged[i]);return (long)(8*count);
}
