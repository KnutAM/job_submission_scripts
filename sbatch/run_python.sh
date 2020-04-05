#!/bin/bash
#SBATCH -N 1            # Number of nodes
#SBATCH -n 1            # Number of processes

# Get input options
while getopts ":s:c" opt; do
  case $opt in
    c)
      change_dir="yes"
      ;;
    s)
      script=$OPTARG
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

# Load python3
module load foss Python SciPy-bundle
module load intel 

# Run analysis
echo python $script

if [ $change_dir ]; then
  cp -pr * $TMPDIR
  cd $TMPDIR
  rm slurm-*.out # Remove output file to avoid overwriting when copying back
  python $script
  echo $?
  cp -pr $TMPDIR/* $SLURM_SUBMIT_DIR/ # Copy all data
else
  python $script
  echo $?
fi

