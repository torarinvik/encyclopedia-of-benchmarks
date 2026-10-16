#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t MAX_CIPHER=4096, KEY_COUNT=17576;
bool allowed(int value){return(value>=9&&value<=13)||(value>=32&&value<=126);}
int word_length(int id){constexpr int lens[8]={3,2,2,2,3,2,4,4};return lens[id];}
int word_char(int id,int j){constexpr const char* words[8]={"the","be","to","of","and","in","that","have"};return words[id][j];}
int lower_ascii(int value){return value>=65&&value<=90?value+32:value;}
bool contains_word(const std::int64_t* input,std::size_t length,const std::uint8_t* keys,std::size_t index,int word){int width=word_length(word);if(length<(std::size_t)width)return false;for(std::size_t start=0;start+(std::size_t)width<=length;++start){bool matched=true;for(int j=0;j<width;++j){std::size_t pos=start+(std::size_t)j;int value=(int)input[pos]^keys[index*3+pos%3];if(lower_ascii(value)!=word_char(word,j)){matched=false;break;}}if(matched)return true;}return false;}
}
extern "C" std::int64_t problem59(const std::int64_t* input,std::size_t length){
 if(input==nullptr||length==0||length>MAX_CIPHER)return -1;for(std::size_t i=0;i<length;++i)if(input[i]<0||input[i]>255)return -1;
 std::uint8_t keys[KEY_COUNT*3]{};std::size_t count=0;
 for(int a=97;a<=122;++a)for(int b=97;b<=122;++b)for(int c=97;c<=122;++c){bool valid=true;for(std::size_t i=0;i<length;++i){int key=i%3==0?a:i%3==1?b:c;if(!allowed((int)input[i]^key)){valid=false;break;}}if(valid){keys[count*3]=(std::uint8_t)a;keys[count*3+1]=(std::uint8_t)b;keys[count*3+2]=(std::uint8_t)c;++count;}}
 for(int word=0;word<8;++word){std::size_t kept=0;for(std::size_t i=0;i<count;++i)if(contains_word(input,length,keys,i,word)){if(kept!=i){keys[kept*3]=keys[i*3];keys[kept*3+1]=keys[i*3+1];keys[kept*3+2]=keys[i*3+2];}++kept;}count=kept;if(count==1)break;}
 if(count==0)return -1;std::int64_t sum=0;for(std::size_t i=0;i<length;++i)sum+=input[i]^keys[i%3];return sum;
}
