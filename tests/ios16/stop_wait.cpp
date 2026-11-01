#include "common/polyfill_thread.h"
#include <cassert>
int main() {
    for (int i = 0; i < 100; ++i) {
        std::mutex mutex;
        std::condition_variable_any cv;
        bool ready = false;
        bool result = true;
        std::atomic<bool> entered{false};
        std::jthread worker([&](std::stop_token token) {
            std::unique_lock lock(mutex);
            entered = true;
            result = Common::CondvarWait(cv, lock, token, [&] { return ready; });
        });
        while (!entered) std::this_thread::yield();
        if (i % 2) {
            { std::lock_guard lock(mutex); ready = true; }
            cv.notify_all();
        } else {
            worker.request_stop();
        }
        worker.join();
        assert(result == bool(i % 2));
    }
    std::mutex mutex;
    std::condition_variable_any cv;
    std::stop_source source;
    source.request_stop();
    std::unique_lock lock(mutex);
    assert(Common::CondvarWait(cv, lock, source.get_token(), [] { return true; }));
    assert(!Common::CondvarWait(cv, lock, source.get_token(), [] { return false; }));
}
