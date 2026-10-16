module xtea;
fn long xtea(long* input,usz length,char* output,usz capacity) @export("xtea"){
 if(input==null||length!=25||input[0]<1||input[0]>64)return -1;for(usz i=1;i<25;i++)if(input[i]<0||input[i]>255)return -1;if(output==null||capacity<8)return -2;uint v0=0;uint v1=0;uint key[4]={0,0,0,0};for(int i=0;i<4;i++){v0=(v0<<8)|(uint)input[1+i];v1=(v1<<8)|(uint)input[5+i];for(int j=0;j<4;j++)key[i]=(key[i]<<8)|(uint)input[9+i*4+j];}uint sum=0;for(long r=0;r<input[0];r++){v0+=(((v1<<4^v1>>5)+v1)^(sum+key[sum&3]));sum+=0x9E3779B9;v1+=(((v0<<4^v0>>5)+v0)^(sum+key[(sum>>11)&3]));}for(int i=0;i<4;i++){output[i]=(char)(v0>>(24-8*i));output[i+4]=(char)(v1>>(24-8*i));}return 8;
}
