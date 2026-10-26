module paq8p_context_mixer;

// Copyright (C) 2008 Matt Mahoney, Serge Osnach, Alexander Ratushnyak, Bill Pettis, Przemyslaw Skibinski, Matthew Fite, wowtiger, Andrew Paterson, Jan Ondrus, Andreas Morphis, Pavel L. Holoborodko, KZ.
// This program is free software; redistribute and/or modify it under the GNU
// General Public License as published by the Free Software Foundation, either
// version 2 or (at your option) any later version. It is provided without any
// warranty, including merchantability or fitness for a particular purpose.
// See https://www.gnu.org/licenses/ for details.
const int[33] ST = {1,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094};
fn int squash(int d){if(d>2047)return 4095;if(d< -2047)return 0;int w=d&127;d=(d>>7)+16;return (ST[d]*(128-w)+ST[d+1]*w+64)>>7;}
fn void make_stretch(int* t){int pi=0;for(int x=-2047;x<=2047;x++){int end=squash(x);for(int j=pi;j<=end;j++)t[j]=x;pi=end+1;}t[4095]=2047;}
fn int dot8(int* t,int* w){int sum=0;for(int i=0;i<8;i+=2)sum+=(t[i]*w[i]+t[i+1]*w[i+1])>>8;return sum;}
fn void train8(int* t,int* w,int err){for(int i=0;i<8;i++){int value=w[i]+(((t[i]*err*2>>16)+1)>>1);if(value< -32768)value=-32768;if(value>32767)value=32767;w[i]=value;}}
fn void put16(char* o,usz p,int value){o[p]=(char)(value&255);o[p+1]=(char)((value>>8)&255);}

fn long paq8p_context_mixer(long* input,usz length,char* output,usz capacity) @export("paq8p_context_mixer") {
    if(input==null||length<12||length>177)return -1;long count=input[0];if(count<1||count>16||length!=1+count.usz()*11)return -1;
    int[16][8] features;int[16] c0;int[16] c1;int[16] targets;usz p=1;
    for(int s=0;s<count;s++){if(input[p]<0||input[p]>1||input[p+1]<0||input[p+1]>1||input[p+2]<0||input[p+2]>1)return -1;c0[s]=(int)input[p];c1[s]=(int)input[p+1];targets[s]=(int)input[p+2];p+=3;for(int j=0;j<8;j++){if(input[p]< -2047||input[p]>2047)return -1;features[s][j]=(int)input[p++];}}
    usz needed=count.usz()*2;if(output==null||capacity<needed)return -2;
    int[4096] stretch;make_stretch(&stretch[0]);int[4][8] outer;int[8] inner;for(int i=0;i<8;i++)inner[i]=32767;int[8] previous_inner;int previous_prediction=2048;int previous_target=0;
    for(int s=0;s<count;s++){if(s>0)train8(&previous_inner[0],&inner[0],((previous_target<<12)-previous_prediction)*7);int[2] contexts={c0[s],2+c1[s]};int[2] model;for(int k=0;k<2;k++)model[k]=squash(dot8(&features[s][0],&outer[contexts[k]][0])>>5);int[8] x={stretch[model[0]],stretch[model[1]],0,0,0,0,0,0};int prediction=squash(dot8(&x[0],&inner[0])>>8);put16(output,s.usz()*2,prediction);for(int k=0;k<2;k++)train8(&features[s][0],&outer[contexts[k]][0],((targets[s]<<12)-model[k])*7);for(int i=0;i<8;i++)previous_inner[i]=x[i];previous_prediction=prediction;previous_target=targets[s];}
    return needed.long();
}
