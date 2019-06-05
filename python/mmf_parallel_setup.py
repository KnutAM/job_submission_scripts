import sys
import os
import numpy as np
import re


def main(argv):
    base_file = argv[1]         # 1st input argument is file name of the base file
    num_optim = int(argv[2])    # 2nd input argument is number of optimizations to run
    base_name = base_file.split('.')[0]
    # Script is run from folder ?/optimization/
    # Input files are located ?/optimization/<base_name>opt<NN>/base_file (where NN is optimization number)
    # Step 1 is to read in the error file. This is always located at ../pspace/<base_name>.err
    data = np.loadtxt('../pspace/' + base_name + '.err', comments='%')
    data = data[data[:,1].argsort(), :] # Sort by lowest error
    mtrlpar = data[0:num_optim, 2:]

    # Step 2 is to change the material parameters in the input file to the parameters from the .err file
    for mpar, n in zip(mtrlpar, range(num_optim)):
        file = base_name + 'opt{:02d}'.format(n) + '/' + base_file
        replace_mpar(file, mpar)


def replace_mpar(file, mpar):
    # Need to identify the row with material parameters
    # First we find the row containing *ipar_init
    # Then we keep looping until we find the input row with the matching number of entries (to skip commented rows)
    # Using the string on this line to search for, we replace this string with the new material parameters

    with open(file, 'r') as fid:
        filestr = fid.read()

    num_mpar = mpar.size
    with open(file, 'r') as fid:
        found_mpar = False
        for line in fid:
            lstr = line.split('!')[0] # Remove comments
            if found_mpar:
                if len(lstr.split()) == num_mpar:
                    break
                elif '*' in lstr:
                    print('couldn''t find material parameters')
                    sys.exit(3)
            if '*ipar_init' in lstr:
                found_mpar = True

    mpar_str = ('{:25.16e}'*num_mpar).format(*mpar)
    filestr=filestr.replace(lstr, mpar_str+'\n')

    with open(file, 'w') as fid:
        fid.write(filestr)


if __name__ == '__main__':
    main(sys.argv)
