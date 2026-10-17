#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr std::size_t max_ops=32, max_capacity=128, max_input=98, max_output_words=320;
struct HashMap { std::int32_t keys[max_capacity]; std::int32_t values[max_capacity]; bool occupied[max_capacity]; std::size_t capacity, size; };
std::size_t hash_index(std::int32_t key, std::size_t cap) {
    return (static_cast<std::uint32_t>(key) & UINT32_C(0x7fffffff)) % cap;
}
void resize_map(HashMap& map, std::size_t next_cap) {
    std::int32_t old_keys[max_capacity], old_values[max_capacity];
    bool old_occupied[max_capacity];
    const auto old_cap=map.capacity;
    for (std::size_t i=0;i<old_cap;++i) { old_keys[i]=map.keys[i]; old_values[i]=map.values[i]; old_occupied[i]=map.occupied[i]; }
    map.capacity=next_cap;
    for (std::size_t i=0;i<next_cap;++i) map.occupied[i]=false;
    for (std::size_t i=0;i<old_cap;++i) if (old_occupied[i]) {
        auto index=hash_index(old_keys[i],next_cap);
        while (map.occupied[index]) index=(index+1)%next_cap;
        map.keys[index]=old_keys[i]; map.values[index]=old_values[i]; map.occupied[index]=true;
    }
}
std::size_t find_slot(const HashMap& map,std::int32_t key) {
    auto index=hash_index(key,map.capacity);
    for(std::size_t probes=0;probes<map.capacity;++probes) {
        if(!map.occupied[index]) return map.capacity;
        if(map.keys[index]==key) return index;
        index=(index+1)%map.capacity;
    }
    return map.capacity;
}
void put(HashMap& map,std::int32_t key,std::int32_t value) {
    if(map.size>map.capacity/2) resize_map(map,map.capacity*2);
    auto index=hash_index(key,map.capacity);
    while(map.occupied[index]) { if(map.keys[index]==key) { map.values[index]=value; return; } index=(index+1)%map.capacity; }
    map.keys[index]=key; map.values[index]=value; map.occupied[index]=true; ++map.size;
}
bool delete_key(HashMap& map,std::int32_t key) {
    auto index=find_slot(map,key); if(index==map.capacity) return false;
    map.occupied[index]=false; map.values[index]=0; index=(index+1)%map.capacity;
    while(map.occupied[index]) {
        const auto k=map.keys[index], v=map.values[index];
        map.occupied[index]=false; map.values[index]=0; --map.size;
        put(map,k,v); index=(index+1)%map.capacity;
    }
    --map.size;
    if(map.size>0 && map.size<=map.capacity/8) resize_map(map,map.capacity/2);
    return true;
}
void append(std::int64_t *words,std::size_t& n,std::int64_t value){words[n++]=value;}
}

extern "C" std::int64_t linear_probing_hash_map(const std::int64_t *input,std::size_t length,
        std::uint8_t *output,std::size_t output_capacity) {
    if(!input||length<2||length>max_input||input[0]<4||input[0]>16||input[1]<0||input[1]>(std::int64_t)max_ops) return -1;
    const auto op_count=static_cast<std::size_t>(input[1]);
    if(length>2+3*op_count) return -1;
    HashMap map{}; map.capacity=static_cast<std::size_t>(input[0]);
    std::int64_t words[max_output_words]; std::size_t word_count=0,pos=2;
    for(std::size_t opi=0;opi<op_count;++opi) {
        if(pos>=length) return -1;
        const auto op=input[pos++];
        if(op==0) {
            if(pos+1>=length) return -1;
            const auto k=input[pos],v=input[pos+1]; pos+=2;
            if(k<INT32_MIN||k>INT32_MAX||v<INT32_MIN||v>INT32_MAX) return -1;
            put(map,(std::int32_t)k,(std::int32_t)v); append(words,word_count,0); append(words,word_count,1);
        } else if(op>=1&&op<=3) {
            if(pos>=length) return -1;
            const auto k=input[pos++]; if(k<INT32_MIN||k>INT32_MAX) return -1;
            const auto key=(std::int32_t)k; const auto index=find_slot(map,key);
            if(op==1) { append(words,word_count,1); if(index==map.capacity){append(words,word_count,1);append(words,word_count,0);} else {append(words,word_count,0);append(words,word_count,map.values[index]);} }
            else if(op==2){append(words,word_count,2);append(words,word_count,delete_key(map,key));}
            else {append(words,word_count,3);append(words,word_count,index!=map.capacity);}
        } else if(op==4){append(words,word_count,4);append(words,word_count,(std::int64_t)map.size);}
        else if(op==5) {
            std::int32_t sorted[max_ops]; std::size_t count=0;
            for(std::size_t i=0;i<map.capacity;++i) if(map.occupied[i]) sorted[count++]=map.keys[i];
            for(std::size_t i=1;i<count;++i){const auto v=sorted[i];std::size_t j=i;while(j>0&&sorted[j-1]>v){sorted[j]=sorted[j-1];--j;}sorted[j]=v;}
            append(words,word_count,5);append(words,word_count,(std::int64_t)count);for(std::size_t i=0;i<count;++i)append(words,word_count,sorted[i]);
        } else return -1;
    }
    if(pos!=length||word_count>max_output_words) return -1;
    const auto bytes=word_count*8;
    if(!output||output_capacity<bytes) return -2;
    for(std::size_t i=0;i<word_count;++i){const auto bits=(std::uint64_t)words[i];for(std::size_t b=0;b<8;++b)output[8*i+b]=(std::uint8_t)(bits>>(8*b));}
    return (std::int64_t)bytes;
}
