import sys
import os
from pathlib import Path
import numpy as np
import argparse
import subprocess
import shutil

cluster = os.environ['SNIC_RESOURCE']    # Gives hebbe on hebbe and vera on vera
repository_path = str((Path(os.path.realpath(__file__)).parent.parent).absolute())

global_settings = {'debug': False, 'debug_nr': 0,
                   'base_file': 'matmodfit.inp',
                   'sbatch_single': repository_path + '/' + 'sbatch/mmf_single.sh',
                   'sbatch_array': repository_path + '/'+ 'sbatch/mmf_array.sh',
                   'sbatch_python': repository_path + '/' + 'sbatch/run_python.sh',    
                   'python_setup': repository_path + '/python/mmf_parallel_setup.py'}

if cluster == 'hebbe':
    default_projects = {'hebbe': 'C3SE2019-1-4', 'mob': 'C3SE507-15-6'}
elif cluster == 'vera':
    default_projects = {'vera': 'C3SE2019-1-4'}

# Requirements for args.base_file:
# All experiment data must be given with absolute paths (even if in same folder)
# Global setting *error_history must be true


def main(args):
    global_settings['base_file'] = args.base_file.split('/')[-1]    # Save name without path
    if args.change_dir:
        global_settings['sbatch_single'] = global_settings['sbatch_single'] + ' -c'
        global_settings['sbatch_array'] = global_settings['sbatch_array'] + ' -c'


    # 1 Setup parameter space run and submit
    # Creates a new input file called pspace.inp which is the same as the args.base_file, but where the optimization
    # part of the base file has been removed and replaced by a parameter space search
    pspaceid = parameter_space(args)
    # This run will result in a file pspace.err which contains args.num_guesses initial guesses with their errors and
    # material parameters.

    # 2 Setup reading of results run and submit it to run after pspaceid has completed
    # Call job with a python script that:
    # * Reads in the errors and material parameters from pspace.err
    # * Creates args.num_optimizations copies of the args.base_file taking the lowest errors
    # * Substitutes the material parameters in each of the copy with the parameters from pspace.err
    setupid = setup_optimization(args, pspaceid)
    # This run will result in args.num_optimizations folders with input files
    # These are named args.base_file + '_opt<i>' where <i> is the number 1,2,...,args.num_optimizations
    # These folders are created directly, only the copying and replacing of material parameters are done by the
    # submitted job.

    # 3 Setup job array simulation based on the input files created by setup_optimization
    # Submits all the optimization runs
    submit_optimization(args, setupid)


def parameter_space(args):
    global_settings['debug'] = args.debug
    base_dir = os.getcwd()
    try:
        os.makedirs('pspace')
    except OSError:
        shutil.rmtree('pspace')
        os.makedirs('pspace')

    shutil.copy(args.base_file, 'pspace/' + args.base_file)
    if args.additional_files:
        for afile in args.additional_files.split(','):
            shutil.copy(afile, 'pspace/' + afile)
    os.chdir('pspace')
    make_pspace_inp(args)
    system_call = create_system_call(global_settings['sbatch_single'], args, 'pspace', None)
    jobid = submit_job(system_call)
    os.chdir(base_dir)

    return jobid


def make_pspace_inp(args):
    with open(args.base_file, 'r') as fid:
        filestr = fid.read()

    optind = filestr.find('<opt>')
    filestr = filestr[0:optind]
    filestr = filestr + '<opt>\n2\n<<start>>\n*algorithm\n2\n*num_sets\n'+str(args.num_guesses)+'\n'
    if args.seed is not None:
        filestr = filestr + '*fixed_seed\n' + str(args.seed) + '\n'

    with open(args.base_file, 'w') as fid:
        fid.write(filestr)


def setup_optimization(args, waitfor_jobid):
    base_dir = os.getcwd()
    the_dir = 'optimization'
    try:
        os.makedirs(the_dir)
    except OSError:
        shutil.rmtree(the_dir)
        os.makedirs(the_dir)

    # Step 1: Create folders to put input files in
    for optnr in range(args.num_optimizations):
        dirname = the_dir + '/' + global_settings['base_file'].split('.')[0] + 'opt{:02d}'.format(optnr)
        os.makedirs(dirname)
        shutil.copy(args.base_file, dirname)
        if args.additional_files:
            for afile in args.additional_files.split(','):
                shutil.copy(afile, dirname)

    
    # Step 2: Create project string (if requested)
    project_string = ''
    if args.partition:
        project_string = project_string + '-p ' + args.partition + ' '
    if args.project:
        project_string = project_string + '-A ' + args.project + ' '
    elif args.partition:
        if args.partition in default_projects:
            project_string = project_string + '-A ' + default_projects[args.partition] + ' '
    

    # Step 3: Submit job
    os.chdir(the_dir)
    system_call = 'sbatch -t 01:00 -J setup -d afterok:' + str(waitfor_jobid) + ' ' \
                  + project_string \
                  + global_settings['sbatch_python'] + ' -s'\
                  + '"' + global_settings['python_setup'] \
                  + ' ' + global_settings['base_file'] + ' ' + str(args.num_optimizations) + '"'
    jobid = submit_job(system_call)
    os.chdir(base_dir)

    return jobid


def submit_optimization(args, waitfor_jobid):
    base_dir = os.getcwd()
    the_dir = 'optimization'
    os.chdir(the_dir)
    system_call = create_system_call(global_settings['sbatch_array'], args, 'opt', waitfor_jobid, array=True)
    submit_job(system_call)
    os.chdir(base_dir)


def create_system_call(script_name, args, jobname, waitfor=None, array=False):
    system_call = 'sbatch '
    if array:
        system_call = system_call + '--array=0-' + str(args.num_optimizations-1) + ' '
    if args.partition:
        system_call = system_call + '-p ' + args.partition + ' '
    if args.project:
        system_call = system_call + '-A ' + args.project + ' '
    elif args.partition:
        if args.partition in default_projects:
            system_call = system_call + '-A ' + default_projects[args.partition] + ' '
        else:
            print('warning: partition not in default_projects specified without specifying project')
    
    if args.time_limit:
        system_call = system_call + '-t ' + args.time_limit + ' '
    if jobname:
        system_call = system_call + '-J ' + jobname + ' '
    if waitfor:
        system_call = system_call + '-d afterok:' + waitfor + ' '

    system_call = system_call + script_name

    return system_call


def submit_job(system_call):
    outfile = 'system_call_output.out'
    if global_settings['debug']:
        global_settings['debug_nr'] = global_settings['debug_nr'] + 1
        print(system_call + ' > ' + outfile)
        output = 'Submitted batch job ' + str(global_settings['debug_nr']+100)
    else:
        print(system_call + ' > ' + outfile)
        os.system(system_call + ' > ' + outfile)
        if os.path.exists(outfile):
            with open(outfile) as outfid:
                output = outfid.read()

    return output.split()[-1]


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='run matmodfit optimization with parallel job submission to cluster')
    parser.add_argument('-b', '--base_file', metavar='base_file', default=None,
                        help='Base file containing global settings, simulations and optimization setup for one '
                              + 'initial guess.')
    parser.add_argument('-a', "--additional_files", metavar='additional_files', default=None,
                        help='Additional files to be copied to the simulation directory. Separate by comma')
    parser.add_argument('-n', "--num_guesses", type=int, default=20, metavar='nguess',
                        help='Number of initial guesses to simulate')
    parser.add_argument('-m', '--num_optimizations', type=int, default=20, metavar='nopt',
                        help='How many of the best initial guesses to optimize from')
    parser.add_argument('-p', '--partition', default=None, metavar='slurm_partition',
                        help='Which partition to use when running the jobs (if none chosen the values in the job ' +
                             'script files will be used)')
    parser.add_argument('-A', '--project', default=None, metavar='slurm_project',
                        help='Which project to use when running the jobs (if none chosen the default value for the ' +
                             'chosen partition will be used, otherwise the value in the script files will be used)')
    parser.add_argument('-t', '--time_limit', default=None, metavar='slurm_tlim',
                        help='Time limit for the jobs (excluding setup of input files) (if none chosen the values in ' +
                             'the job script files will be used)')
    parser.add_argument('-c', '--change_dir', action="store_true", 
                        help="Change directory to TMPDIR during run to avoid excessive file copying")
    parser.add_argument('-d', '--debug', help="test function", action="store_true")
    parser.add_argument('-s', '--seed', default=None, metavar='seed', 
                        help="Use to have a fixed seed for latin hypercube sampling")

    main(parser.parse_args())
