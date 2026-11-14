#include <cstddef>
#include <cstdint>
#include <utility>
#include <vector>

using Point = std::pair<int64_t,int64_t>;
static int64_t score(const std::vector<Point>& p, int row, int col) {
    int n = static_cast<int>(p.size());
    if (col <= row) return col-row;
    if (col >= row+n) return -1;
    auto dx = p[row].first-p[col%n].first, dy = p[row].second-p[col%n].second;
    return dx*dx+dy*dy;
}
static void maxima(const std::vector<Point>& p, const std::vector<int>& rows,
                   const std::vector<int>& columns, std::vector<int>& answer) {
    if (rows.empty()) return;
    std::vector<int> reduced;
    for (int col : columns) {
        while (!reduced.empty() && score(p,rows[reduced.size()-1],col) >
               score(p,rows[reduced.size()-1],reduced.back())) reduced.pop_back();
        if (reduced.size() < rows.size()) reduced.push_back(col);
    }
    std::vector<int> odd;
    for (size_t i=1; i<rows.size(); i+=2) odd.push_back(rows[i]);
    maxima(p,odd,reduced,answer);
    size_t low=0;
    for (size_t i=0; i<rows.size(); i+=2) {
        size_t high=reduced.size()-1;
        if (i+1<rows.size()) { high=low; while (reduced[high] != answer[rows[i+1]]) ++high; }
        size_t best=low;
        for (size_t j=low+1; j<=high; ++j) if (score(p,rows[i],reduced[j]) > score(p,rows[i],reduced[best])) best=j;
        answer[rows[i]]=reduced[best]; low=high;
    }
}
extern "C" int64_t all_farthest_neighbors_convex(const int64_t *input, size_t length,
                                                  uint8_t *output, size_t capacity) {
    if (!input || length<7 || length>129 || input[0]<3 || input[0]>64) return -1;
    int n=static_cast<int>(input[0]);
    if (length != 1+2*static_cast<size_t>(n)) return -1;
    std::vector<Point> points;
    for (int i=0; i<n; ++i) {
        auto x=input[1+2*i], y=input[2+2*i];
        if (x < -1000000 || x > 1000000 || y < -1000000 || y > 1000000) return -1;
        points.emplace_back(x,y);
    }
    for (int i=0; i<n; ++i) {
        auto a=points[i], b=points[(i+1)%n], c=points[(i+2)%n];
        if ((b.first-a.first)*(c.second-b.second)-(b.second-a.second)*(c.first-b.first) >= 0) return -1;
    }
    if (!output || capacity < 8*static_cast<size_t>(n)) return -2;
    std::vector<int> rows, columns, answer(n);
    for (int i=0; i<n; ++i) rows.push_back(i);
    for (int i=0; i<2*n-1; ++i) columns.push_back(i);
    maxima(points,rows,columns,answer);
    for (int i=0; i<n; ++i) {
        auto index=static_cast<uint64_t>(answer[i]%n);
        for (size_t b=0; b<8; ++b) output[8*static_cast<size_t>(i)+b]=static_cast<uint8_t>(index >> (8*b));
    }
    return 8*n;
}
