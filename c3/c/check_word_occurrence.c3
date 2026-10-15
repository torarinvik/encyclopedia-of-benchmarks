module check_word_occurrence;
const MAX_INPUT:usz=1024;const MAX_ENTRIES:usz=1025;
fn bool ws(uchar c){return (c>=9&&c<=13)||c==32;}
fn uchar lower_ascii(uchar c){return c>='A'&&c<='Z'?(uchar)(c+('a'-'A')):c;}
fn bool forbidden(uchar* s,usz n){char*[7] names={"constructor","tostring","tolocalestring","valueof","hasownproperty","isprototypeof","propertyisenumerable"};usz[7] lens={11,8,14,7,14,13,20};for(usz x=0;x<7;x++){if(n!=lens[x])continue;usz i=0;for(;i<n;i++)if(lower_ascii(s[i])!=(uchar)names[x][i])break;if(i==n)return true;}return false;}
fn void put32(uchar* out,usz* pos,ulong x){for(usz i=0;i<4;i++){out[*pos]=(uchar)(x&255);*pos+=1;x>>=8;}}
fn long check_word_occurrence(long* input,usz length,uchar* output,usz capacity) @export("check_word_occurrence"){
 if(input==null||length<2||input[0]<0||input[0]>1||input[1]<0||input[1]>1024||length!=(usz)input[1]+2)return -1;usz n=(usz)input[1];uchar[MAX_INPUT] text;
 for(usz i=0;i<n;i++){long v=input[i+2];if(v<0||v>127)return -1;uchar c=(uchar)v;if(!((c>='A'&&c<='Z')||(c>='a'&&c<='z')||ws(c)))return -1;text[i]=input[0]!=0?lower_ascii(c):c;}
 usz[MAX_ENTRIES] starts,lens;uint[MAX_ENTRIES] counts=zeroed;usz entries=0,i=0,start=0;
 for(;;){if(i==n||ws(text[i])){usz len=i-start;if(forbidden(&text[start],len))return -1;usz j=0;for(;j<entries;j++)if(lens[j]==len){usz q=0;for(;q<len&&text[starts[j]+q]==text[start+q];q++){}if(q==len)break;}if(j==entries){starts[j]=start;lens[j]=len;entries++;}counts[j]++;if(i==n)break;while(i<n&&ws(text[i]))i++;start=i;}else i++;}
 usz need=4;for(usz j=0;j<entries;j++)need+=8+lens[j];if(capacity<need||output==null)return -2;usz pos=0;put32(output,&pos,(ulong)entries);for(usz j=0;j<entries;j++){put32(output,&pos,(ulong)lens[j]);for(usz q=0;q<lens[j];q++){output[pos]=text[starts[j]+q];pos++;}put32(output,&pos,(ulong)counts[j]);}return (long)pos;
}
