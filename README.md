# Grading scaffold for CSE 591, project 1

The Dockerfile is just an example. Please replace it with your own.

I will run this as:

```
cd /your/project/directory
cp /path/to/grade.sh .
cp -a /path/to/testcases .
./grade.sh
```

grade.sh will run your docker container as (for gdb or qemu):

```
docker run --privileged --rm -id --name=grader -v /path/to/testcase:/testcase tograde /fuzz -Q -i /testcase/seeds -o /testcase/output /testcase/binary
```

or (for valgrind):

```
docker run --privileged --rm -id --name=grader -v /path/to/testcase:/testcase tograde /fuzz -V -i /testcase/seeds -o /testcase/output /testcase/binary
```
