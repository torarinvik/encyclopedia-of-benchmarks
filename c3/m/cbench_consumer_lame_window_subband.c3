/*
 * Copyright (c) 1999 Takehiro TOMINAGA
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */
module cbench_consumer_lame_window_subband;
import "core:math";

const usz SAMPLE_COUNT=511, WINDOW_COUNT=256, INPUT_COUNT=767, MAX_INPUT_LENGTH=768;
const usz BAND_COUNT=32, OUTPUT_BYTES=256;
const double PI=3.14159265358979323846264338327950288;
const int[15] S_OFFSETS={334,398,462,14,78,142,206,16,80,144,208,272,336,400,464};
const int[15] T_OFFSETS={176,112,48,496,432,368,304,494,430,366,302,238,174,110,46};

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits=(ulong)value;
    for(usz byte=0;byte<8;byte++){output[offset+byte]=(char)(bits&255);bits>>=8;}
}
fn long round_q1000(double value){double scaled=value*1000.0;double magnitude=scaled<0.0?-scaled:scaled;long rounded=(long)(magnitude+0.5);return scaled<0.0?-rounded:rounded;}
fn bool valid(long* input,usz length){
    if(input==null||length==0||length>MAX_INPUT_LENGTH||length!=INPUT_COUNT)return false;
    for(usz i=0;i<SAMPLE_COUNT;i++)if(input[i]<-32768||input[i]>32767)return false;
    for(usz i=0;i<WINDOW_COUNT;i++)if(input[SAMPLE_COUNT+i]<-4500000||input[SAMPLE_COUNT+i]>36000000)return false;
    for(usz i=0;i<WINDOW_COUNT;i++)if((i==0||(i>=8&&(i-8)%16==0))&&input[SAMPLE_COUNT+i]<=25000000)return false;
    return true;
}
fn void filterbank(long* input,double window[256],double bands[32]){
    double maximum=window[248],mmax[31],mm[16][31];usz wp=0,wr=0;double w=window[wp++];mmax[15]=w/maximum;
    for(usz k=0;k<7;k++)window[wr++]=window[wp++]/w;
    for(int i=14;i>=0;i--){w=window[wp++];mmax[i]=w/maximum;mmax[30-i]=w/maximum;for(usz k=0;k<15;k++)window[wr++]=window[wp++]/w;}
    wp++;for(usz k=0;k<7;k++)window[wr++]=window[wp++]/maximum;
    for(int i=15;i>=0;i--)for(int k=1;k<32;k++)mm[i][k-1]=math.cos((2*i+1)*k*PI/64.0)*mmax[k-1];
    double inner[31]={0};usz coeff=0;double t=(double)input[255];
    t+=(double)(input[223]-input[287])*window[coeff++];t+=(double)(input[191]+input[319])*window[coeff++];
    t+=(double)(input[159]-input[351])*window[coeff++];t+=(double)(input[127]+input[383])*window[coeff++];
    t+=(double)(input[95]-input[415])*window[coeff++];t+=(double)(input[63]+input[447])*window[coeff++];t+=(double)(input[31]-input[479])*window[coeff++];inner[15]=t;
    for(int i=14;i>=0;i--){double s=(double)input[270-i];t=(double)input[240+i];for(int k=0;k<15;k++){w=window[coeff++];int si=S_OFFSETS[k]+(k<7?-i:i);int ti=T_OFFSETS[k]+(k<7?i:-i);double sv=(double)input[si]*w,tv=(double)input[ti]*w;if(k>=11)s-=sv;else s+=sv;if(k>=7&&k<11)t-=tv;else t+=tv;}inner[30-i]=s;inner[i]=t;}
    double s=(double)input[239];s+=(double)input[175]*window[coeff++];s+=(double)input[111]*window[coeff++];s+=(double)input[47]*window[coeff++];s-=(double)input[303]*window[coeff++];s-=(double)input[367]*window[coeff++];s-=(double)input[431]*window[coeff++];s-=(double)input[495]*window[coeff++];
    for(int i=15;i>=0;i--){double s0=s,s1=t*mm[i][0];usz at=1;for(int j=0;j<15;j++){s0+=mm[i][2*j+1]*inner[at++];s1+=mm[i][2*j+2]*inner[at++];}bands[i]=s0+s1;bands[31-i]=s0-s1;}
}
fn long cbench_consumer_lame_window_subband(long* input,usz input_length,char* output,usz output_capacity) @export("cbench_consumer_lame_window_subband"){
    if(!valid(input,input_length))return -1;double window[256];for(usz i=0;i<WINDOW_COUNT;i++)window[i]=(double)input[SAMPLE_COUNT+i]/1000000000.0;
    double bands[32];filterbank(input,window,bands);long staged[32];for(usz i=0;i<BAND_COUNT;i++)staged[i]=round_q1000(bands[i]);
    if(output==null||output_capacity<OUTPUT_BYTES)return -2;for(usz i=0;i<BAND_COUNT;i++)store_i64_le(output,8*i,staged[i]);return (long)OUTPUT_BYTES;
}
