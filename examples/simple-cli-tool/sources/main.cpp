#include <assert.h>

#include <cstring>
#include <iostream>
#include <functional>
#include <string>
#include <vector>


static constexpr std::size_t kMaxArgLength = 64;


static int get_string_length(const std::string& s) {
    std::size_t l = 0;
    for (; l < s.size(); ++l) {
        if (s[l] == '\0')
            return l;
    }

    return l;
}


static bool test_1() {
    return get_string_length("") == std::string("").length();
}

static bool test_2() {
    return get_string_length("\0") == std::string("\0").length();
}

static bool test_3() {
    return get_string_length("complex case A") == std::string("complex case A").length();
}

static bool test_4() {
    return get_string_length("complex case B") == std::string("complex case B").length();
}


int main(int argc, char** argv) {
    int testid = -1;
    std::string name;

    std::vector<std::function<bool()>> tests = {
        &test_1, &test_2, &test_3, &test_4
    };

    for (int i = 1; i < argc; ++i) {
        if (std::strncmp("--test", argv[i], kMaxArgLength) == 0) {
            i += 1;
            if (i == argc) {
                std::cerr << "should specify id of the test" << std::endl;
                return 1;
            }

            assert(i < argc);

            char buffer[16];
            std::strncpy(buffer, argv[i], sizeof(buffer)-1);
            buffer[15] = '\0';

            try {
                testid = std::stoi(std::string(buffer, std::strlen(buffer)));
            } catch (std::exception& e) {
                std::cerr << "failed to read id of the test: " << e.what() << std::endl;
                return 1;
            }

            if (testid < 1 || testid > tests.size()) {
                std::cerr << "testid must be in the range of [1; " << tests.size() << "]" << std::endl;
                return 1;
            }
            testid -= 1;

            break;
        }

        if (name.length() > 0) {
            std::cerr << "unexpected argument at " << i << std::endl;
            return 1;
        }

        name.assign(argv[i]);
    }

    if (testid >= 0) {
        assert(testid < tests.size());
        return tests[testid]() ? 0 : 1;
    }

    std::cout << "Length of the string " << name << " is " << get_string_length(name) << std::endl;

    return 0;
}
