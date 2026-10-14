module dutch_national_flag_sort

// Dutch national flag sort for values restricted to 0, 1, and 2.
@[export: 'dutch_national_flag_sort']
pub fn dutch_national_flag_sort(mut values &i64, length usize) {
	mut low := usize(0)
	mut middle := usize(0)
	mut high := length
	for middle < high {
		if unsafe { values[middle] } == 0 {
			temporary := unsafe { values[low] }
			unsafe {
				values[low] = values[middle]
				values[middle] = temporary
			}
			low++
			middle++
		} else if unsafe { values[middle] } == 1 {
			middle++
		} else {
			high--
			temporary := unsafe { values[middle] }
			unsafe {
				values[middle] = values[high]
				values[high] = temporary
			}
		}
	}
}
