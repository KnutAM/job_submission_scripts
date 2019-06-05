#!/bin/bash
#SBATCH -J matmodfit    # Name of job
#SBATCH -o matmodfit.out# Output log
#SBATCH -N 1            # Number of nodes
#SBATCH -n 1            # Number of processes
#SBATCH -t 2-00         # Walltime limit (days-hours)
#SBATCH -A C3SE507-15-6 # Project (main queue: "C3SE2018-1-17", mob: "C3SE507-15-6")
#SBATCH -p mob          # Partition ("hebbe" main queue, "mob" private at MoB)

while getopts ":c" opt; do
  case $opt in
    c)
      change_dir="yes"
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

# Find input file
inputfile=$(find -name *.inp)

# Load modules (required for some shared libraries)
module load intel
module load ifort/2018.3.222-GCC-7.3.0-2.30  impi/2018.3.222 Python/3.7.0

echo "Change directory: " $change_dir
if [ $change_dir ]; then
    echo "Directory is changed"
	cp -r * $TMPDIR
    cd $TMPDIR
fi

# Run analysis
matmodfit $inputfile

echo $?

if [ $change_dir ]; then
    # Copy back output data and change directory, option p ensures attributes preserved, r recursively (include folder and their files)
    cp -pr $TMPDIR/* $SLURM_SUBMIT_DIR # Copy all data
fi

