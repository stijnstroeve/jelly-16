testbench_dir="testbenches/"
to_test=()

if [ $# -eq 0 ]
  then
    for file in $testbench_dir*.vhd; do
        test_name=$(basename "$file" .vhd)
        to_test+=("$test_name")
    done
else
    to_test=($@)
fi

for testbench in "${to_test[@]}"; do
    echo "Running testbench: $testbench"
    ./scripts/run.sh $testbench
done

echo "All testbenches completed."