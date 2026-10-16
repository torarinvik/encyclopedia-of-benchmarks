module entropy;
extern fn double log2(double value);
extern fn double floor(double value);
const usz MAX_TEXT=512;const usz ALPHABET=128;
fn int round_even(double value){double lo=floor(value);double fraction=value-lo;if(fraction<0.5)return (int)lo;if(fraction>0.5)return (int)(lo+1.0);int n=(int)lo;return n%2==0?n:n+1;}
fn usz emit_line(char* out,usz pos,int value){int v=value;if(v<0){out[pos++]='-';v=-v;}if(v>=10)out[pos++]=(char)('0'+v/10);out[pos++]=(char)('0'+v%10);out[pos++]='.';out[pos++]='0';out[pos++]='\n';return pos;}
fn long entropy(long* input,usz length,char* output,usz capacity) @export("entropy") {
 if(input==null||length<2||length>MAX_TEXT+1)return -1L;long n=input[0];if(n<1||n>MAX_TEXT||length!=(usz)(n+1))return -1L;
 uint singles[128] = {0}; uint pairs[16384] = {0};for(usz i=0;i<(usz)n;i++){long c=input[i+1];if(c<0||c>=128)return -1L;singles[(usz)c]++;}pairs[32*128+(usz)input[1]]++;for(usz i=0;i+1<(usz)n;i++)pairs[(usz)input[i+1]*128+(usz)input[i+2]]++;
 int alpha[27]={32,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122};double s1=0.0,s2=0.0;for(usz i=0;i<27;i++){uint c=singles[alpha[i]];if(c){double p=(double)c/(double)n;s1+=p*log2(p);}}for(usz i=0;i<27;i++)for(usz j=0;j<27;j++){uint c=pairs[alpha[i]*128+alpha[j]];if(c){double p=(double)c/(double)n;s2+=p*log2(p);}}
 char temp[32] = {0};usz pos=0;pos=emit_line(temp,pos,round_even(-s1));pos=emit_line(temp,pos,round_even(-s2));pos=emit_line(temp,pos,round_even((-s2)-(-s1)));if(output==null||capacity<pos)return -2L;for(usz i=0;i<pos;i++)output[i]=temp[i];return (long)pos;
}
