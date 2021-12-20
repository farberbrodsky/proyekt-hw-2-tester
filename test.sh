#!/bin/bash

# compile code
SRC_DIR="$(find -name setup.py -printf '%h')"
if [ "$SRC_DIR" == "" ]; then
    echo "Can't find setup.py"
    exit 1
fi

TEST_DIR="$(find -name test_data)"
if [ "$TEST_DIR" == "" ]; then
    echo "Can't find test_data"
    exit 1
fi

# go to SRC_DIR and compile
pushd .
cd "$SRC_DIR"
python3 setup.py build_ext --inplace
popd

while read line; do
    if [ "${line}" == "" ]; then break; fi
    # e.g.: 2. k=7, max_iter = not provided, eps=0, input_2_db_1, input_2_db_2
    k=$((cut -d "," -f 1 | cut -d "=" -f 2 | sed "s/ //g") <<< "${line}")
    max_iter=$((cut -d "," -f 2 | cut -d "=" -f 2 | sed "s/ //g") <<< "${line}")
    eps=$((cut -d "," -f 3 | cut -d "=" -f 2 | sed "s/ //g") <<< "${line}")
    input_1=$((cut -d "," -f 4 | cut -d "=" -f 2 | sed "s/ //g") <<< "${line}")
    input_2=$((cut -d "," -f 5 | cut -d "=" -f 2 | sed "s/ //g") <<< "${line}")

    expected_output=$((cut -d "." -f 1) <<< "$line")
    echo "Running test ${expected_output}..."
    expected_output="$TEST_DIR/output_${expected_output}.txt"
    input_1="$TEST_DIR/${input_1}.txt"
    input_2="$TEST_DIR/${input_2}.txt"

    # run the test
    if [ "$max_iter" == "notprovided" ]; then
        output=$(python3 $SRC_DIR/kmeans_pp.py "$k" "$eps" "$input_1" "$input_2")
    else
        output=$(python3 $SRC_DIR/kmeans_pp.py "$k" "$max_iter" "$eps" "$input_1" "$input_2")
    fi

    if ! diff /dev/stdin "$expected_output" <<< "$output" >/dev/null; then
        echo -e "\e[31mWRONG OUTPUT!\e[0m"
        diff /dev/stdin "$expected_output" <<< "$output"
        echo "k is $k, max_iter is $max_iter, eps is $eps"
        echo "inputs are $input_1 and $input_2"
        echo "correct output in $expected_output"
    fi
done < <(cat "$TEST_DIR/test_readme.txt"; echo -e "\n")

echo "Done!"
