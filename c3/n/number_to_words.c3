module number_to_words;
const char*[20] SMALL={"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten","Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen"};
const char*[10] TENS={"","","Twenty","Thirty","Forty","Fifty","Sixty","Seventy","Eighty","Ninety"};
const char*[5] SCALE={"","Thousand","Million","Billion","Trillion"};
fn usz slen(char*s){usz n=0;while(s[n]!=0)n++;return n;}
fn void emit(char*b,usz*n,char*w){if(*n>0)b[(*n)++]=' ';usz m=slen(w);for(usz i=0;i<m;i++)b[(*n)++]=w[i];}
fn void chunk(char*b,usz*n,uint x){if(x>=100){emit(b,n,(char*)SMALL[x/100]);emit(b,n,"Hundred");x%=100;}if(x>=20){emit(b,n,(char*)TENS[x/10]);x%=10;}if(x>0&&x<20)emit(b,n,(char*)SMALL[x]);}
fn long number_to_words(long*v,usz n,char*out,usz cap) @export("number_to_words") {
if(v==null||n<3||n>9||v[0]<-1||v[0]>1||v[1]<0||v[1]>999999999999999||v[2]<0||v[2]>6||n!=(usz)v[2]+3)return -1;
bool nz=v[1]!=0;for(usz i=3;i<n;i++){if(v[i]<0||v[i]>9)return -1;if(v[i]!=0)nz=true;}if((nz&&v[0]==0)||(!nz&&v[0]!=0))return -1;
char[256] b;usz used=0;if(v[0]<0)emit(&b[0],&used,"Negative");ulong whole=(ulong)v[1];uint[5] groups;for(usz i=0;i<5;i++){groups[i]=(uint)(whole%1000);whole/=1000;}bool any=false;usz i=5;while(i>0){i--;if(groups[i]!=0){chunk(&b[0],&used,groups[i]);if(i>0)emit(&b[0],&used,(char*)SCALE[i]);any=true;}}if(!any)emit(&b[0],&used,"Zero");bool fnz=false;for(usz j=3;j<n;j++)if(v[j]!=0)fnz=true;if(fnz){emit(&b[0],&used,"Point");for(usz j=3;j<n;j++)emit(&b[0],&used,(char*)SMALL[v[j]]);}if(used>cap)return -2;for(usz j=0;j<used;j++)out[j]=(char)b[j];return (long)used;
}
