#!/bin/bash

TIMEOUT=10

echo "[*] Building your docker container..."
docker build -t tograde .
echo "[*] Docker container built."
echo "****************************************************************************************************"
function test_fuzzer
{
	TRACER_NAME=$1
	TRACER_OPTION=$2
	TOTAL_TESTS=0
	TOTAL_CRASHED=0

	echo "[*] Starting to fuzz with tracer $TRACER_NAME..."
	for testcase in tests/*/
	do
		echo "[-] Launching testcase $testcase with $TRACER_NAME tracer..."
		TOTAL_TESTS=$(($TOTAL_TESTS+1))

		rm -rf $testcase/output
		CONTAINER_ID=$(docker run --privileged --rm -id --name=grader -v $PWD/$testcase:/testcase tograde /fuzz -$TRACER_OPTION -i /testcase/seeds -o /testcase/output /testcase/binary)
		echo "[-] running container $CONTAINER_ID"
		timeout $TIMEOUT docker wait $CONTAINER_ID
		echo "[-] container $CONTAINER_ID completed with return code of $?"
		docker kill $CONTAINER_ID
		
		# check if process is still running, probably status is still removing
		docker ps -a | grep "grader"
		while [ $? -eq 0 ]
		do
		    echo "[-] Container $CONTAINER_ID is still being removed, sleeping before retesting..."
		    sleep 10
		    docker ps -a | grep "grader"
		done

		echo "[-] Checking for crashes..."
		CRASHED=0
		for output in $(find $testcase/output -type f)
		do
			cat $output | timeout 10 $testcase/binary >/dev/null 2>/dev/null
			if [ $? -eq 139 ]
			then
				CRASHED=1
				break
			fi
		done

		if [ $CRASHED -eq 1 ]
		then
			echo "[+] Crash found!"
			TOTAL_CRASHED=$(($TOTAL_CRASHED+1))
		else
			echo "[-] CRASH NOT FOUND"
		fi
	done

	echo "[*] Crashed $TOTAL_CRASHED of $TOTAL_TESTS testcases using the $TRACER_NAME tracer."
}

test_fuzzer gdb/qemu Q
test_fuzzer valgrind V

