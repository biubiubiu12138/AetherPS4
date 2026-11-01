#include <charconv>
#include <cassert>
#include <cmath>
#include <cstdlib>
#include <limits>
#include <string>

template<class T> void roundtrip(T value) {
    char buffer[2048];
    auto result = std::to_chars(buffer, buffer + sizeof(buffer) - 1, value);
    assert(result.ec == std::errc{});
    *result.ptr = 0;
    const auto decoded = static_cast<T>(std::strtod(buffer, nullptr));
    assert(decoded == value);
    assert(std::signbit(decoded) == std::signbit(value));
}
int main() {
    for (double value : {0.0, -0.0, 1.25, -1e100, 1e-100,
                         std::numeric_limits<double>::max(),
                         std::numeric_limits<double>::denorm_min()}) roundtrip(value);
    for (float value : {0.f, -0.f, 1.25f, std::numeric_limits<float>::max(),
                        std::numeric_limits<float>::denorm_min()}) roundtrip(value);
    char buffer[64];
    auto result = std::to_chars(buffer, buffer + sizeof(buffer), 1.25,
                                std::chars_format::fixed, 3);
    assert(result.ec == std::errc{});
    assert(std::string(buffer, result.ptr) == "1.250");
    result = std::to_chars(buffer, buffer + 1, 12345.0);
    assert(result.ec == std::errc::value_too_large);
    result = std::to_chars(buffer, buffer + sizeof(buffer), 1.5L, std::chars_format::hex);
    assert(result.ec == std::errc{});
    assert(std::string(buffer, result.ptr) == "1.8p+0");
}
