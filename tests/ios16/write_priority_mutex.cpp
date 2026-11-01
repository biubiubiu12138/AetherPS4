#include <FEXCore/Utils/WritePriorityMutex.h>
#include <cassert>
#include <mutex>
#include <shared_mutex>
#include <thread>
#include <vector>
int main() {
  FEXCore::Utils::WritePriorityMutex::Mutex mutex;
  unsigned long value = 0;
  std::vector<std::thread> workers;
  for (int i = 0; i < 4; ++i) workers.emplace_back([&] {
    for (int n = 0; n < 20000; ++n) {
      std::lock_guard guard(mutex);
      ++value;
    }
  });
  for (int i = 0; i < 4; ++i) workers.emplace_back([&] {
    unsigned long previous = 0;
    for (int n = 0; n < 20000; ++n) {
      std::shared_lock guard(mutex);
      assert(value >= previous);
      previous = value;
    }
  });
  for (auto& worker : workers) worker.join();
  assert(value == 80000);
  assert(mutex.try_lock());
  assert(!mutex.try_lock_shared());
  mutex.unlock();
  assert(mutex.try_lock_shared());
  assert(!mutex.try_lock());
  mutex.unlock_shared();
}
