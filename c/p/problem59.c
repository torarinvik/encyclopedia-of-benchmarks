/* TheAlgorithms/Python Project Euler 59, over a bundled ciphertext array. */
#include <stddef.h>
#include <stdint.h>
#define MAX_CIPHER 4096
#define KEY_COUNT 17576
static int allowed(int value) { return (value >= 9 && value <= 13) || (value >= 32 && value <= 126); }
static int word_length(int id) { static const int lengths[8]={3,2,2,2,3,2,4,4}; return lengths[id]; }
static int word_char(int id,int j) {
    static const char *words[8]={"the","be","to","of","and","in","that","have"};
    return words[id][j];
}
static int lower_ascii(int value) { return value >= 65 && value <= 90 ? value + 32 : value; }
static int contains_word(const int64_t *input,size_t length,const uint8_t *keys,size_t index,int word) {
    const int width=word_length(word);
    if (length < (size_t)width) return 0;
    for (size_t start=0;start+(size_t)width<=length;++start) {
        int matched=1;
        for (int j=0;j<width;++j) {
            const size_t pos=start+(size_t)j;
            const int value=(int)input[pos] ^ keys[index*3+pos%3];
            if (lower_ascii(value)!=word_char(word,j)) { matched=0; break; }
        }
        if (matched) return 1;
    }
    return 0;
}
int64_t problem59(const int64_t *input,size_t length) {
    if (input==NULL || length==0 || length>MAX_CIPHER) return -1;
    for(size_t i=0;i<length;++i) if(input[i]<0 || input[i]>255) return -1;
    uint8_t keys[KEY_COUNT*3]; size_t count=0;
    for(int a=97;a<=122;++a) for(int b=97;b<=122;++b) for(int c=97;c<=122;++c) {
        int valid=1;
        for(size_t i=0;i<length;++i) { int key=(i%3==0?a:i%3==1?b:c); if(!allowed((int)input[i]^key)){valid=0;break;} }
        if(valid){keys[count*3]=(uint8_t)a;keys[count*3+1]=(uint8_t)b;keys[count*3+2]=(uint8_t)c;++count;}
    }
    for(int word=0;word<8;++word){
        size_t kept=0;
        for(size_t i=0;i<count;++i) if(contains_word(input,length,keys,i,word)){ if(kept!=i){keys[kept*3]=keys[i*3];keys[kept*3+1]=keys[i*3+1];keys[kept*3+2]=keys[i*3+2];} ++kept; }
        count=kept; if(count==1) break;
    }
    if(count==0) return -1;
    int64_t sum=0; for(size_t i=0;i<length;++i) sum+=input[i]^keys[i%3];
    return sum;
}
