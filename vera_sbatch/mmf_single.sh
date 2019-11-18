#!/bin/bash
#SBATCH -J mmfsV  		# Name of job
#SBATCH -o mmfsV_slurm.out	# Output log
#SBATCH -N 1            # Number of nodes
#SBATCH -n 1            # Number of processes
#SBATCH -t 2-00         # Walltime limit (days-hours)
#SBATCH -A C3SE2019-1-4 # Project
#SBATCH -p vera         # Partition

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
module load foss Python SciPy-bundle
module load intel

echo "Change directory: " $change_dir
if [ $change_dir ]; then
    cp -r * $TMPDIR
    cd $TMPDIR
fi

# Run analysis
matmodfit $inputfile &> $SLURM_SUBMIT_DIR/$inputfile.out

echo $?

if [ $change_dir ]; then
    # Copy back output data and change directory, option p ensures attributes preserved, r recursively (include folder and their files)
    cp -pr $TMPDIR/* $SLURM_SUBMIT_DIR # Copy all data
fi

