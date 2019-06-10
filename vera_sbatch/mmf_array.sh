#!/bin/bash
#SBATCH -J mmfaV   		# Name of job
#SBATCH -o mmfaV.out	# Output log
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
DIRS=($(find * -type d))

# Load modules (required for some shared libraries)
module load intel
module load iccifort/2018.3.222-GCC-7.3.0-2.30  impi/2018.3.222 Python/3.6.7

# Change to correct directory
THE_DIR=${DIRS[$SLURM_ARRAY_TASK_ID]}

cd $THE_DIR

inputfile=$(find -name *.inp)

# Run analysis
echo "Analysis nr. $SLURM_ARRAY_TASK_ID: $THE_DIR"
echo "Inputfile = $inputfile"

if [ $change_dir ]; then
    cp -pr * $TMPDIR
    cd $TMPDIR
	while sleep 1h; do
		rsync *.err $SLURM_SUBMIT_DIR/$THE_DIR
	done &
	LOOPPID=$!
	matmodfit $inputfile
	kill $LOOPPID
	cp -pr $TMPDIR/* $SLURM_SUBMIT_DIR/$THE_DIR # Copy all data
else
	matmodfit $inputfile
fi
