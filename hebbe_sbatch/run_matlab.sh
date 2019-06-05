#!/bin/bash
#SBATCH -J matlab       # Name of job
#SBATCH -o matlab.out   # Output log default name
#SBATCH -N 1            # Number of nodes
#SBATCH -n 10           # Number of processes
#SBATCH -t 1-00         # Walltime limit (days-hours)
#SBATCH -A C3SE2018-1-17# Project (main queue: "C3SE2018-1-17", mob: "C3SE507-15-6")
#SBATCH -p hebbe        # Partition ("hebbe" main queue, "mob" private at MoB)
#SBATCH --mail-user=knutan@chalmers.se
#SBATCH --mail-type=ALL # Mail for all changes

## Example calling line:
 # sbatch -o test.out -n 10 run_matlab.sh -i my.m

matlab_parallel_setup="/c3se/users/knutan/Hebbe/jobscripts/matlab_parallel_setup"
# Get input options
while getopts ":i:" opt; do
  case $opt in
    i)
      inputfile=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Check that input file is given
if [ -z $inputfile ]; then
    echo "No input file selected, this is mandatory!"
    exit 1
fi

# Setup environment
module load MATLAB
matlab -nodesktop -nosplash -r "run('$matlab_parallel_setup');$inputfile" < /dev/null
