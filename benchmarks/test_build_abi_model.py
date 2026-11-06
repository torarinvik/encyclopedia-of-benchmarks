import unittest
from build_abi import workload_declares_model

class WorkloadModelTest(unittest.TestCase):
    def test_model_locations_and_conflicts(self):
        model = 'i64_array_bytes_output_call'
        self.assertTrue(workload_declares_model({'comparison_model': model}, model))
        self.assertTrue(workload_declares_model({'measurement': {'comparison_model': model}}, model))
        self.assertTrue(workload_declares_model({'comparison_model': model, 'measurement': {'comparison_model': model}}, model))
        self.assertFalse(workload_declares_model({}, model))
        self.assertFalse(workload_declares_model({'comparison_model': model, 'measurement': {'comparison_model': 'other'}}, model))
        self.assertFalse(workload_declares_model({'comparison_model': 'other'}, model))

if __name__ == '__main__':
    unittest.main()
