#! python3

import argparse
import json
import re

def main():
    parser = argparse.ArgumentParser(
            prog="compile_commands.json include dir fixer"
    )

    parser.add_argument('builddir', type=str)

    args = parser.parse_args()

    source_file = open(args.builddir + '/compile_commands.json', 'r')
    source_file_content = source_file.read()
    source_file.close()

    source_json = json.loads(source_file_content)

    for entry in source_json:
        entry_dir = entry['directory']
        entry_command = entry['command']
        tmp = re.findall(r'[@]\S*', entry_command)
        for m in tmp:
            includes_file = open(entry_dir + '/' + m[1:], 'r')
            includes = includes_file.read()
            includes_file.close()
            entry_command = entry_command.replace(m, includes.strip())
        if 'mingw' in entry['command']:
            entry['command'] = entry_command + ' -I/usr/lib/gcc/x86_64-w64-mingw32/10-posix/include/c++' + ' -I/usr/lib/gcc/x86_64-w64-mingw32/10-posix/include/c++/x86_64-w64-mingw32'
            entry['command'] += ' -D_GLIBCXX_HAS_GTHREADS'
        elif 'msvc' in entry['command']:
            tmp_ix = entry_command.find('/bin/x64/cl ')
            msvc_path = entry_command[:tmp_ix]
            entry['command'] += f' -external:I{msvc_path}/VC/Tools/MSVC/14.42.34433/include'
            entry['command'] += f' -external:I{msvc_path}/Windows\\ Kits/10/Include/10.0.22621.0/ucrt'
            entry['command'] += f' -external:I{msvc_path}/Windows\\ Kits/10/Include/10.0.22621.0/um'
            entry['command'] += f' -external:I{msvc_path}/Windows\\ Kits/10/Include/10.0.22621.0/shared'
    fixed_file = open(args.builddir + '/compile_commands.json', 'w')
    fixed_file.write(json.dumps(source_json, indent=4))
    fixed_file.close()

    fixed_file = open(args.builddir + '/compile_commands_fixed.json', 'w')
    fixed_file.write(source_file_content)
    fixed_file.close()

    print(f"FIXED")

if __name__ == "__main__":
    main()

