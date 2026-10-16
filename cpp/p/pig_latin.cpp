#include <cstddef>
#include <cstdint>
extern "C" std::int64_t pig_latin(const std::int64_t* v,std::size_t n,std::uint8_t* out,std::size_t cap) noexcept {
 if(!v||n<1||n>65||v[0]<0||v[0]>64||n!=std::size_t(v[0])+1)return -1;
 auto count=std::size_t(v[0]);if(!count)return 0;if(count+3>cap||!out)return -2;
 std::size_t pivot=count;
 for(std::size_t i=0;i<count;i++){auto x=v[i+1];if(x>=65&&x<=90)x+=32;if(x<97||x>122)return -1;out[i]=std::uint8_t(x);if(pivot==count&&(x=='a'||x=='e'||x=='i'||x=='o'||x=='u'))pivot=i;}
 if(pivot==count)return -1;
 if(pivot==0){out[count]='w';out[count+1]='a';out[count+2]='y';return std::int64_t(count+3);}
 for(std::size_t i=0;i<pivot;i++)out[count+i]=out[i];
 for(std::size_t i=0;i<count-pivot;i++)out[i]=out[pivot+i];
 out[count]='a';out[count+1]='y';return std::int64_t(count+2);
}
