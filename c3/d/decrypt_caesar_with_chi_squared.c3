module decrypt_caesar_with_chi_squared;
const double[26] FREQ = {0.08497,0.01492,0.02202,0.04253,0.11162,0.02228,0.02015,0.06094,0.07546,0.00153,0.01292,0.04025,0.02406,0.06749,0.07507,0.01929,0.00095,0.07587,0.06327,0.09356,0.02758,0.00978,0.02560,0.00150,0.01994,0.00077};
extern fn void* memcpy(void* destination,void* source,usz length);
fn void put_f64(double* value,char* output){memcpy(output,value,8);}
fn long decrypt_caesar_with_chi_squared(long* input,usz length,char* output,usz capacity) @export("decrypt_caesar_with_chi_squared") {
 if(input==null||length<1||length>129||input[0]<0||input[0]>128||(usz)input[0]!=length-1)return -1;for(usz i=1;i<length;i++)if(input[i]<0||input[i]>127)return -1;
 usz text_length=length-1;if(output==null||capacity<8+text_length)return -2;
 char[128] best;char[128] candidate;double best_score=1e300;long best_shift=0;
 for(long shift=0;shift<26;shift++){
  long[26] counts;for(usz j=0;j<26;j++)counts[j]=0;for(usz i=0;i<text_length;i++){long v=input[i+1];if(v>=65&&v<=90){v=97+(v-65-shift+2600)%26;}else if(v>=97&&v<=122){v=97+(v-97-shift+2600)%26;}candidate[i]=(char)v;if(v>=97&&v<=122)counts[v-97]++;}
  double score=0.0;for(usz j=0;j<26;j++){long n=counts[j];if(n>0){double expected=FREQ[j]*(double)n;double delta=(double)n-expected;score+=(delta*delta)/expected;}}
  bool less=score<best_score;if(score==best_score){for(usz i=0;i<text_length;i++){if(candidate[i]<best[i]){less=true;break;}if(candidate[i]>best[i])break;}}
  if(less){best_score=score;best_shift=shift;for(usz i=0;i<text_length;i++)best[i]=candidate[i];}
 }
 put_f64(&best_score,output);for(usz i=0;i<text_length;i++)output[8+i]=best[i];return best_shift;
}
