#include <stddef.h>
#include <stdint.h>

#define MAX_TARGET 6
#define MAX_WORDS 4
#define MAX_WAYS 4096

int64_t all_construct(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if(input==NULL||length<2||input[0]<0||input[0]>MAX_TARGET)return -1;
    size_t n=(size_t)input[0];
    for(size_t i=0;i<n;i++)if(input[i+1]<'a'||input[i+1]>'z')return -1;
    size_t word_count_slot=1+n;
    if(word_count_slot>=length||input[word_count_slot]<0||input[word_count_slot]>MAX_WORDS)return -1;
    size_t words=(size_t)input[word_count_slot],cursor=word_count_slot+1;
    size_t starts[MAX_WORDS]={0},word_lengths[MAX_WORDS]={0};
    for(size_t w=0;w<words;w++){
        if(cursor>=length||input[cursor]<1||input[cursor]>MAX_TARGET)return -1;
        size_t wl=(size_t)input[cursor++];if(cursor+wl>length)return -1;
        starts[w]=cursor;word_lengths[w]=wl;
        for(size_t j=0;j<wl;j++)if(input[cursor+j]<'a'||input[cursor+j]>'z')return -1;
        cursor+=wl;
    }
    if(cursor!=length)return -1;
    uint8_t paths[MAX_TARGET+1][MAX_WAYS][MAX_TARGET]={0};
    uint8_t path_lengths[MAX_TARGET+1][MAX_WAYS]={0};
    size_t counts[MAX_TARGET+1]={0};counts[0]=1;
    for(size_t pos=0;pos<n;pos++){
        for(size_t w=0;w<words;w++){
            size_t wl=word_lengths[w];if(wl>n-pos)continue;
            size_t j=0;while(j<wl&&input[pos+1+j]==input[starts[w]+j])j++;
            if(j!=wl)continue;
            size_t end=pos+wl;
            for(size_t r=0;r<counts[pos];r++){
                size_t dest=counts[end]++;if(dest>=MAX_WAYS)return -1;
                uint8_t plen=path_lengths[pos][r];
                for(size_t k=0;k<plen;k++)paths[end][dest][k]=paths[pos][r][k];
                paths[end][dest][plen]=(uint8_t)w;path_lengths[end][dest]=(uint8_t)(plen+1);
            }
        }
    }
    size_t required=0;for(size_t r=0;r<counts[n];r++){required+=1;for(size_t k=0;k<path_lengths[n][r];k++){size_t w=paths[n][r][k];required+=1+word_lengths[w];}}
    if(capacity<required||(required!=0&&output==NULL))return -2;
    size_t written=0;
    for(size_t r=0;r<counts[n];r++){
        uint8_t plen=path_lengths[n][r];output[written++]=plen;
        for(size_t k=0;k<plen;k++){size_t w=paths[n][r][k];output[written++]=(uint8_t)word_lengths[w];for(size_t j=0;j<word_lengths[w];j++)output[written++]=(uint8_t)input[starts[w]+j];}
    }
    return (int64_t)counts[n];
}
