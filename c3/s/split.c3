module split;
const usz MAX_TEXT=256;
fn long split(long* input,usz length,char* output,usz capacity) @export("split"){
 if(input==null||length<2||length>MAX_TEXT+3||input[0]<0||input[0]>256||input[1]<0||input[1]>127)return -1;
 usz n=(usz)input[0];if(length!=n+2)return -1;
 for(usz i=0;i<n;i++)if(input[i+2]<0||input[i+2]>127)return -1;
 if(n>0&&input[n+1]==input[1])return -1;
 usz separators=0;for(usz i=0;i<n;i++)if(input[i+2]==input[1])separators++;if(n>0&&separators==0)return -1;
 usz count=separators+1,required=2+2*count+n-separators;if(output==null||capacity<required)return -2;
 output[0]=(char)count;output[1]=(char)(count>>8);usz pos=2,start=0;
 for(usz i=0;i<=n;i++){if(i==n||input[i+2]==input[1]){usz field=i-start;output[pos++]=(char)field;output[pos++]=(char)(field>>8);for(usz j=start;j<i;j++)output[pos++]=(char)input[j+2];start=i+1;}}
 return (long)required;
}
