#include <iostream>

int main() {
#if defined(WITH_TOOLCHAIN)
    std::cout << "OK!" << std::endl;
    return 0;
#else
    std::cout << "NOT OK!" << std::endl;
    return 1;
#endif
}
