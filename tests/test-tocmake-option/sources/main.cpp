#include <iostream>

int main() {
#if defined(CUSTOM_OPTION)
    std::cout << "OK!" << std::endl;
    return 0;
#else
    std::cout << "FAIL!" << std::endl;
    return 1;
#endif
}

