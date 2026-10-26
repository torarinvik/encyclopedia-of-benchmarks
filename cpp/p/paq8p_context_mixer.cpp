/* Copyright (C) 2008 Matt Mahoney, Serge Osnach, Alexander Ratushnyak, Bill Pettis, Przemyslaw Skibinski, Matthew Fite, wowtiger, Andrew Paterson, Jan Ondrus, Andreas Morphis, Pavel L. Holoborodko, KZ.
 * This program is free software; you can redistribute and/or modify it under
 * the GNU General Public License as published by the Free Software Foundation;
 * either version 2 of the License, or (at your option) any later version.
 * It is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See https://www.gnu.org/licenses/ for details. */
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

static constexpr int ST[33]={1,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094};
static int squash(int d){if(d>2047)return 4095;if(d< -2047)return 0;int w=d&127;d=(d>>7)+16;return (ST[d]*(128-w)+ST[d+1]*w+64)>>7;}
static void make_stretch(std::array<int,4096>& t){int pi=0;for(int x=-2047;x<=2047;++x){int end=squash(x);for(int j=pi;j<=end;++j)t[j]=x;pi=end+1;}t[4095]=2047;}
static int dot8(const std::array<int,8>& t,const std::array<int,8>& w){int sum=0;for(int i=0;i<8;i+=2)sum+=(t[i]*w[i]+t[i+1]*w[i+1])>>8;return sum;}
static void train8(const std::array<int,8>& t,std::array<int,8>& w,int err){for(int i=0;i<8;++i){int value=w[i]+(((t[i]*err*2>>16)+1)>>1);w[i]=std::clamp(value,-32768,32767);}}

extern "C" std::int64_t paq8p_context_mixer(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept {
    if(input==nullptr||length<12||length>177)return -1;auto count=input[0];if(count<1||count>16||length!=1+static_cast<std::size_t>(count)*11)return -1;
    std::array<std::array<int,8>,16> features{};std::array<int,16> c0{},c1{},target{};std::size_t p=1;
    for(int s=0;s<count;++s){if(input[p]<0||input[p]>1||input[p+1]<0||input[p+1]>1||input[p+2]<0||input[p+2]>1)return -1;c0[s]=int(input[p++]);c1[s]=int(input[p++]);target[s]=int(input[p++]);for(int j=0;j<8;++j){if(input[p]<-2047||input[p]>2047)return -1;features[s][j]=int(input[p++]);}}
    const std::size_t needed=std::size_t(count)*2;if(output==nullptr||capacity<needed)return -2;
    std::array<int,4096> stretch{};make_stretch(stretch);std::array<std::array<int,8>,4> outer{};std::array<int,8> inner;inner.fill(32767);
    std::array<int,8> prev_inner{};int prev_prediction=2048,prev_target=0;
    for(int s=0;s<count;++s){if(s>0)train8(prev_inner,inner,((prev_target<<12)-prev_prediction)*7);int contexts[2]={c0[s],2+c1[s]};int model[2];for(int k=0;k<2;++k)model[k]=squash(dot8(features[s],outer[contexts[k]])>>5);std::array<int,8> x={stretch[model[0]],stretch[model[1]],0,0,0,0,0,0};int prediction=squash(dot8(x,inner)>>8);output[2*s]=std::uint8_t(prediction&255);output[2*s+1]=std::uint8_t((prediction>>8)&255);for(int k=0;k<2;++k)train8(features[s],outer[contexts[k]],((target[s]<<12)-model[k])*7);prev_inner=x;prev_prediction=prediction;prev_target=target[s];}
    return std::int64_t(needed);
}
