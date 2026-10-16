module conway;
const usz MAX_TEXT_LENGTH=128;
fn usz decimal_digits(usz value){usz digits=1;while(value>=10){value/=10;digits+=1;}return digits;}
fn long conway(long* input,usz length,char* output,usz capacity) @export("conway") {
 if(input==null||length<2||length>MAX_TEXT_LENGTH+1)return -1L;long n=input[0];if(n<1||n>MAX_TEXT_LENGTH||length!=(usz)(n+1))return -1L;
 for(usz i=0;i<(usz)n;i++)if(input[i+1]<0||input[i+1]>127)return -1L;
 usz needed=0;for(usz i=0;i<(usz)n;){usz j=i+1;while(j<(usz)n&&(input[j]==input[j+1]||input[j]==10||input[j]==13))j++;needed+=decimal_digits(j-i)+1;i=j;}
 if(output==null||capacity<needed)return -2L;usz pos=0;
 for(usz i=0;i<(usz)n;){usz j=i+1;while(j<(usz)n&&(input[j]==input[j+1]||input[j]==10||input[j]==13))j++;usz run=j-i,start=pos;do{output[pos++]=(char)('0'+run%10);run/=10;}while(run);for(usz a=start,b=pos-1;a<b;a++,b--){char t=output[a];output[a]=output[b];output[b]=t;}output[pos++]=(char)input[i+1];i=j;}
 return (long)pos;
}
